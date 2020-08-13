# require 'gsl'
# include GSL
module ApplicationHelper
  L = 1020
  E1_INDICIES = [0, (L/3 - 1)]
  E2_INDICIES = [(L/3), (2*L/3 - 1)]
  E3_INDICIES = [(2*L/3), (L - 1)]
  SYNC_CODE_LENGTH = 20
  WATERMARK_DECODED_LENGTH = 18
  WATERMARK_LENGTH = 40
  VITERBI_DIR = Rails.application.credentials[Rails.env.to_sym][:viterbi_dir]
  PROGRESS_FRAMES = 50

  def find_leak_source(original_file, leaker_file_path)
    # open leaker file
    lkr_file = RubyAudio::Sound.open(leaker_file_path)

    # get file info
    channelCount, sampleRate, frames, sections, lengthS = get_file_metadata(lkr_file)

    encodedBits = ""
    encodedBitBuilder = StringIO.new

    buf = RubyAudio::Buffer.new("float", L, channelCount)
    while lkr_file.read(buf) != 0
      if buf.real_size == L

        channel = 0

        # calculate AOAAs
        gosAOAAs = calcGOSAOAAs(buf, channel)
        # sort AOAAs
        hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])
        a,b = calcA_B(hashAOAA)

        if a >= b
          encodedBitBuilder << '1'
        else
          encodedBitBuilder << '0'
        end
      end
    end

    encodedBits = encodedBitBuilder.string
    pp "Encoded bits: " + encodedBits

    allValidWatermarks = original_file.sharedfiles.map { |x| x.watermark }
    # byebug
    watermark = extract_watermark_from_bits(encodedBits, allValidWatermarks)

    if watermark.nil?
      sharedUser = nil
      pp "watermark = N/A"
    else
      pp "watermark = " + watermark
      sharedfile = Sharedfile.find_by watermark: watermark, uploadedfile_id: original_file.id
      if sharedfile.nil?
        sharedUser = nil
      else
        sharedUser = User.find_by id: sharedfile.user_id
      end
    end

    File.delete(leaker_file_path) if File.exists? leaker_file_path

    sharedUser
  end

  def extract_watermark_from_bits(encodedBits, allValidWatermarks)
    watermarkCandidates = []

    index = 0
    while index < (encodedBits.length - WATERMARK_LENGTH)
      decodedChunk = fec_decode(encodedBits[index,WATERMARK_LENGTH])
      if allValidWatermarks.include? decodedChunk
        watermarkCandidates.append(decodedChunk)
        index += WATERMARK_LENGTH
      else
        index += 1
      end
    end

    watermark = nil
    if watermarkCandidates.length > 0
      watermark, count = most_common_value(watermarkCandidates)
      pp "Most Common Value: " + watermark.to_s + " with count: " + count.to_s + " watermarked%: " + (((count * WATERMARK_LENGTH) / encodedBits.length.to_f) * 100 ).to_i.to_s + "%"
    end

    watermark
  end

  def most_common_value(a)
    val, count = a.group_by(&:itself).values.map { |x| [x.first , x.length] }.max { |a, b| a[1] <=> b[1] }
    # pp "Most Common Value: " + val.to_s + " with count: " + count.to_s
    [val, count]
  end

  def audio_file_to_graph_data(uploadedfile)
    og_file_path = "#{Dir.tmpdir}/#{[*('a'..'z'),*('0'..'9')].shuffle[0,8].join}"
    File.open(og_file_path, 'wb') do |file|
      file.write(uploadedfile.audio_file.download)
    end

    # open tmp file
    og_file = RubyAudio::Sound.open(og_file_path)

    # get file info
    channelCount = og_file.info.channels
    sampleRate = og_file.info.samplerate
    frames = og_file.info.frames
    sections = og_file.info.sections
    lengthS = og_file.info.length
    duration = frames.to_f / sampleRate.to_f
    frameDuration = duration / frames.to_f

    pp "frames: " + frames.to_s
    pp "sampleRate: " + sampleRate.to_s
    pp "duration: " + duration.to_s
    pp "frameDuration: " + frameDuration.to_s

    channel = 0
    data = Array.new
    buf = RubyAudio::Buffer.new("float", frames, channelCount)
    RubyAudio::Sound.open(og_file_path) do |file|
      while file.read(buf) != 0

        (0...frames).each do |x|
          data.append([x * frameDuration, buf[x][channel]])

          if buf[x][channel] > 1.0
            pp "@ s=" + (x * frameDuration).to_s + " -> " + buf[x][channel].to_s
          end
        end

      end
    end

    File.delete(og_file_path)

    data
  end

  def embed_watermark(uploadedfile, watermark)

    # copy uploadedfile to tmp dir
    og_file_path, uniqueIdentifier = generateTemporaryUploadedfilePath(uploadedfile)

    # open tmp file
    og_file = RubyAudio::Sound.open(og_file_path)

    # get file info
    channelCount, sampleRate, frames, sections, lengthS = get_file_metadata(og_file)

    buf = RubyAudio::Buffer.new("float", L, channelCount)
    out = nil
    out_file_path = "#{Dir.tmpdir}/#{uploadedfile.fileName + '_watermarked'}#{uniqueIdentifier}"
    result_file_path = out_file_path

    RubyAudio::Sound.open(og_file_path) do |file|
      out = File.open(out_file_path, 'w') if out.nil?

      tmp_audible_watermark_count = 0
      gosIndex = 0
      channel = 0

      codeIndex = 0
      codeBlock = fec_encode(watermark)

      minVal = -1
      maxVal = 1
      d_sum = 0.0 # to calculate avg later
      while file.read(buf) != 0
        if gosIndex == 0
          minVal = buf[0][channel]
          maxVal = minVal
        end
        puts "---------GOS " + gosIndex.to_s + "----------"

        # clone og buffer for spectrum analysis
        og_buf = copy_buf(buf)
        d_init = 0.0 # 0.05
        if buf.real_size == L

          embed_bit = nil

          if codeIndex == codeBlock.length
            codeBlock = fec_encode(watermark)
            codeIndex = 0
            embed_bit = codeBlock[codeIndex].to_i
          else
            embed_bit = codeBlock[codeIndex].to_i
            codeIndex += 1
          end

          d = d_init
          watermark_audible = true
          while watermark_audible && (d >= 0.0)
            buf = copy_buf(og_buf)

            # compute values from GOS
            hashAOAA, a, b, thd1 = computeGOSValues(buf, channel, d)

            if embed_bit == 1
              pp "Embedding 1 bit"
              satisfiesCondition = (a - b) >= thd1

              if satisfiesCondition
                pp "Condition Satisfied, no operation needed."
                watermark_audible = false
              else
                pp "Scaling amplitudes with d = " + d.to_s
                embed_1(buf,channel,hashAOAA, a, b, thd1, d, PROGRESS_FRAMES)
                # # analyze spectrum
                # watermark_audible = analyze_spectrum(buf, og_buf, channel, sampleRate)
                # if watermark_audible
                #   tmp_audible_watermark_count += 1
                #   d -= 0.01
                # end
              end
            else
              pp "Embedding 0 bit"
              satisfiesCondition = (b - a) >= thd1

              if satisfiesCondition
                pp "Condition Satisfied, no operation needed."
                watermark_audible = false
              else
                pp "Scaling amplitudes with d = " + d.to_s
                embed_0(buf,channel,hashAOAA, a, b, thd1, d, PROGRESS_FRAMES)
                # # analyze spectrum
                # watermark_audible = analyze_spectrum(buf, og_buf, channel, sampleRate)
                # if watermark_audible
                #   tmp_audible_watermark_count += 1
                #   d -= 0.01
                # end
              end
            end

            # find min, max vals
            maxVal, minVal = findGOSMinMax(buf, channel, maxVal, minVal)

            # analyze spectrum
            # watermark_audible = analyze_spectrum(buf, og_buf, channel, sampleRate)
            watermark_audible = false #NOTE analyze sprectrum disabled
            if watermark_audible
              d -= 0.01

              if d < 0.0
                tmp_audible_watermark_count += 1
                pp "GOS mark AUDIBLE********************"
              end
            else
              pp "GOS mark INAUDIBLE"
            end

          end

          if d > 0.0
            d_sum += d
          end

          # TEST changed bit
          gosAOAAs = calcGOSAOAAs(buf, channel)
          hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])
          a,b = calcA_B(hashAOAA)
          if a >= b
            pp "New GOS Value: 1"
          else
            pp "New GOS Value: 0"
          end
        else
          pp "GOS too small to embed watermark"
        end

        # write to tmp out file
        gosLine = (buf.map { |frame| frame[channel] }).join(' ') + "\n"
        out.write(gosLine)

        puts "----------------------"
        gosIndex += 1
      end
      pp "audible_watermark_count: " + tmp_audible_watermark_count.to_s
      pp "audible GOS percentage: " + (tmp_audible_watermark_count/gosIndex).to_s
      pp "avg d_avg = " + (d_sum / (gosIndex + 1)).to_s
      pp "minVal: " + (minVal).to_s
      pp "maxVal: " + (maxVal).to_s

      out.close if out

      # rescale if needed
      ogFile = RubyAudio::Sound.open(og_file_path)
      if minVal < -1.0 || 1.0 < maxVal
        pp "Rescaling Values and copying to file"
        out = nil
        out_file_scaled_path = out_file_path + "_scaled"
        out = RubyAudio::Sound.open(out_file_scaled_path, 'w', ogFile.info.clone) if out.nil?

        # calculate scaling factor
        scalingFactor = 1.0
        if maxVal > minVal.abs
          scalingFactor = 1.0 / maxVal
        else
          scalingFactor = 1.0 / minVal.abs
        end

        File.foreach(out_file_path) do |line|
          gosLine = line.split(" ")
          ogFile.read(buf)
          (0...gosLine.length).each do |x|
            frameVal = gosLine[x].to_f
            scaledVal = frameVal * scalingFactor
            tmp = buf[x].clone
            tmp[channel] = scaledVal
            buf[x] = tmp
          end
          out.write(buf)
        end
        out.close if out
        File.delete(out_file_path)
        result_file_path = out_file_scaled_path
      else
        pp "Copying to file"
        out = nil
        out_file_unscaled_path = out_file_path + "_nonscaled"
        out = RubyAudio::Sound.open(out_file_unscaled_path, 'w', ogFile.info.clone) if out.nil?

        File.foreach(out_file_path) do |line|
          gosLine = line.split(" ")
          ogFile.read(buf)
          (0...gosLine.length).each do |x|
            frameVal = gosLine[x].to_f
            tmp = buf[x].clone
            tmp[channel] = frameVal
            buf[x] = tmp
          end
          out.write(buf)
        end
        out.close if out
        File.delete(out_file_path)
        result_file_path = out_file_unscaled_path
      end

      ogFile.close if ogFile

    end

    # delete tmp OG file
    File.delete(og_file_path)

    result_file_path
  end

  def findGOSMinMax(buf, channel, maxVal, minVal)
    (0...L).each do |x|
      if buf[x][channel] > maxVal
        maxVal = buf[x][channel]
      elsif buf[x][channel] < minVal
        minVal = buf[x][channel]
      end
    end
    [maxVal, minVal]
  end

  def computeGOSValues(buf, channel, d)
    # calculate AOAAs
    gosAOAAs = calcGOSAOAAs(buf, channel)

    # sort AOAAs
    hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])

    #pp "eMin: " + hashAOAA["eMin"].to_s
    #pp "eMid: " + hashAOAA["eMid"].to_s
    #pp "eMax: " + hashAOAA["eMax"].to_s

    a,b = calcA_B(hashAOAA)

    if a >= b
      pp "Initial GOS Value: 1"
    else
      pp "Initial GOS Value: 0"
    end

    thd1 = calcThd1(hashAOAA, d)

    [hashAOAA, a, b, thd1]
  end

  def get_file_metadata(file)
    channelCount = file.info.channels
    sampleRate = file.info.samplerate
    frames = file.info.frames
    sections = file.info.sections
    lengthS = file.info.length

    pp "******************OG File*************************"
    pp "channels: " + channelCount.to_s
    pp "sample rate: " + sampleRate.to_s
    pp "frames: " + frames.to_s
    pp "sections: " + sections.to_s
    pp "length: " + lengthS.to_s

    [channelCount,sampleRate,frames,sections,lengthS]
  end

  def generateTemporaryUploadedfilePath(uploadedfile)
    uniqueIdentifier = Time.now.strftime("%Y%m%d%k%M%S%N").to_s + SecureRandom.alphanumeric(10)
    og_file_path = "#{Dir.tmpdir}/#{uploadedfile.fileName}#{uniqueIdentifier}"
    File.open(og_file_path, 'wb') do |file|
      file.write(uploadedfile.audio_file.download)
    end
    [og_file_path, uniqueIdentifier]
  end

  def fec_encode(msg, constraint = 3, generatorPolynomials = [7,5])
    command = 'viterbi_main --encode'
    encodedMsg = %x<#{VITERBI_DIR}#{command} #{constraint} #{generatorPolynomials.join(" ")} #{msg}>
    encodedMsg.gsub("\n", "")
  end

  def fec_decode(msg, constraint = 3, generatorPolynomials = [7,5])
    command = 'viterbi_main'
    encodedMsg = %x<#{VITERBI_DIR}#{command} #{constraint} #{generatorPolynomials.join(" ")} #{msg}>
    encodedMsg.gsub("\n", "")
  end

  def generate_watermark
    watermark = ""
    unique_watermark = false
    while !unique_watermark
      watermark_builder = StringIO.new
      WATERMARK_DECODED_LENGTH.times do
        watermark_builder << generate_binary_bit
      end
      watermark = watermark_builder.string

      # TODO change to make unique for uploadedFile
      if (Sharedfile.find_by watermark: watermark) == nil
        unique_watermark = true
      end
    end

    watermark
  end

  def generate_binary_bit
    bit = ""
    if [true, false].sample
      bit = "1"
    else
      bit = "0"
    end
    bit
  end


  def copy_buf(original)
    copy = original.dup

    (0...original.real_size).each do |frame|
      frameCpy = []
      original[frame].each do |value|
        frameCpy.append(value.dup)
      end

      copy[frame] = frameCpy
    end

    copy
  end

  # takes frequency in khz and returns threshold in dB
  def SPL_Thresh(freq)
    a = 3.6 * (freq ** -0.8)
    b = 6.5 * (Math::E ** (-0.6 * ((freq - 3.3) ** 2) ))
    c = 0.001 * (freq ** 4)

    a - b + c
  end

  def analyze_spectrum(buf, og_buf, channel, sampleRate)
    audible_watermark = false

    pp "Spectrum Analysis"
    # compute r (watermark signal)
    r = Array.new
    (0..(L-1)).each do |x|
      r.push(buf[x][channel] - og_buf[x][channel])
    end

    4.times do
      r.push(0.0)
    end

    #fft
    r_spec = fft(r)

    frames = 1024.0
    audible_frame_count = 0
    over_thresh_count = 0

    r_hat = Array.new
    x_val = Array.new
    (0..((L-1 + 4))/2).each do |x|
      # r_hat[x] = (20 * Math.log(Math.sqrt((r_spec[x].real ** 2) + (r_spec[x].imaginary ** 2)))).abs
      # r_hat[x] =  (((r_spec[x].real ** 2) + (r_spec[x].imaginary ** 2)).abs)


      r_hat[x] = 20 * Math.log(Math.sqrt((r_spec[x].real ** 2) + (r_spec[x].imaginary ** 2)))
      # r_hat[x] = (10 * Math.log(r_hat[x]))
      x_val[x] = (x * sampleRate / 2) / (frames / 2) / 1000

      if 0.02 <= x_val[x] && x_val[x] <= 20
        thresh = SPL_Thresh(x_val[x])
        audible_frame_count += 1

        if thresh <= r_hat[x]
          over_thresh_count += 1
        end
      end

    end

    under_thresh_per = ((audible_frame_count - over_thresh_count) / audible_frame_count) * 100
    pp "Under Thresh percent: " + under_thresh_per.to_s

    if under_thresh_per < 100 # 85
      pp "AUDIBLE WATERMARK@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      audible_watermark = true
    end

    audible_watermark
  end

  def fft(vec)
    return vec if vec.size <= 1

    even = Array.new(vec.size / 2) { |i| vec[2 * i] }
    odd  = Array.new(vec.size / 2) { |i| vec[2 * i + 1] }

    fft_even = fft(even)
    fft_odd  = fft(odd)

    fft_even.concat(fft_even)
    fft_odd.concat(fft_odd)

    Array.new(vec.size) {|i| fft_even[i] + fft_odd [i] * omega(-i, vec.size)}
  end

  def omega(k, n)
    Math::E ** Complex(0, 2 * Math::PI * k / n)
  end

  def embed_0(buf,channel,hashAOAA, a, b, thd1, d, progressFrames)
    delta = (thd1 - (b - a)) / 3
    w_up = 1 + (delta / hashAOAA["eMid"][1])
    w_down = 1 - (delta / hashAOAA["eMin"][1])
    w_delta = 0.01

    count = 0
    buf_clone = nil
    while !((b - a) >= thd1)
      count += 1
      buf_clone = buf.map(&:clone)

      # scale up eMax
      scaleUpSection(buf_clone, channel, hashAOAA["eMid"][2][0], hashAOAA["eMid"][2][1], w_up, progressFrames)

      # scale down eMid
      scaleDownSection(buf_clone, channel, hashAOAA["eMin"][2][0], hashAOAA["eMin"][2][1], w_down, progressFrames)

      # reevaluate A & B
      gosAOAAs = calcGOSAOAAs(buf_clone, channel)
      hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])
      a,b = calcA_B(hashAOAA)
      thd1 = calcThd1(hashAOAA, d)

      if count > 20000
        raise "error: count > 20000"
      end

      # increment w
      w_up += w_delta
      w_down -= w_delta
    end

    pp "count: " + count.to_s

    if buf_clone != nil
      # copy back to OG buffer
      buf_clone.each_with_index do |item, index|
        buf[index] = item
      end
    end
  end

  def embed_1(buf,channel,hashAOAA, a, b, thd1, d, progressFrames)
    delta = (thd1 - (a - b)) / 3
    w_up = 1 + (delta / hashAOAA["eMax"][1])
    w_down = 1 - (delta / hashAOAA["eMid"][1])
    w_delta = 0.01 # was 0.05, 0.0001

    count = 0
    buf_clone = nil
    while !((a - b) >= thd1)
      count += 1
      buf_clone = buf.map(&:clone)

      # scale up eMax
      scaleUpSection(buf_clone, channel, hashAOAA["eMax"][2][0], hashAOAA["eMax"][2][1], w_up, progressFrames)

      # scale down eMid
      scaleDownSection(buf_clone, channel, hashAOAA["eMid"][2][0], hashAOAA["eMid"][2][1], w_down, progressFrames)

      # reevaluate A & B
      gosAOAAs = calcGOSAOAAs(buf_clone, channel)
      hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])
      a,b = calcA_B(hashAOAA)
      thd1 = calcThd1(hashAOAA, d)

      if count > 20000
        raise "error: count > 20000"
      end

      # increment w
      w_up += w_delta
      w_down -= w_delta
    end

    pp "count: " + count.to_s

    if buf_clone != nil
      # copy back to OG buffer
      buf_clone.each_with_index do |item, index|
        buf[index] = item
      end
    end
  end

  def scaleUpSection(buf, channel, startIndex, endIndex, w, progressFrames)
    w_0 = 1
    w_delta = (w - w_0) / progressFrames

    (startIndex..(startIndex + progressFrames - 1)).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]

      if w_0 < w
        w_0 += w_delta
      else
        w_0 = w
      end
    end

    w_0 = w

    ((startIndex + progressFrames)..(endIndex - progressFrames)).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]
    end

    ((endIndex - progressFrames + 1)..endIndex).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]

      if w_0 > 1
        w_0 -= w_delta
      else
        w_0 = 1
      end
    end

  end

  def scaleDownSection(buf, channel, startIndex, endIndex, w, progressFrames)
    w_0 = 1
    w_delta = (w_0 - w) / progressFrames

    (startIndex..(startIndex + progressFrames - 1)).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]

      if w_0 > w
        w_0 -= w_delta
      else
        w_0 = w
      end
    end

    w_0 = w

    ((startIndex + progressFrames)..(endIndex - progressFrames)).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]
    end

    ((endIndex - progressFrames + 1)..endIndex).each do |x|
      buf[x][channel] = w_0 * buf[x][channel]

      if w_0 < 1
        w_0 += w_delta
      else
        w_0 = 1
      end
    end

  end

  # calculate A & B values from hashAOAA
  def calcA_B(hashAOAA)
    a = hashAOAA["eMax"][1] - hashAOAA["eMid"][1]
    b = hashAOAA["eMid"][1] - hashAOAA["eMin"][1]
    [a,b]
  end

  def calcThd1(hashAOAA, d)
    (hashAOAA["eMax"][1] + 2 * hashAOAA["eMid"][1] + hashAOAA["eMin"][1]) * d
  end

  # sort AOAAs into hash specifying min, mid, and max AOAAs
  def sortAOAAs(e1, e2, e3)
    sorted = [e1,e2,e3].sort

    hashAOAA = Hash.new
    if sorted[0] == e1
      hashAOAA["eMin"] = ["e1", e1, E1_INDICIES]
      if sorted[1] == e2
        hashAOAA["eMid"] = ["e2", e2, E2_INDICIES]
        hashAOAA["eMax"] = ["e3", e3, E3_INDICIES]
      else
        hashAOAA["eMax"] = ["e2", e2, E2_INDICIES]
        hashAOAA["eMid"] = ["e3", e3, E3_INDICIES]
      end
    elsif sorted[0] == e2
      hashAOAA["eMin"] = ["e2", e2, E2_INDICIES]
      if sorted[1] == e1
        hashAOAA["eMid"] = ["e1", e1, E1_INDICIES]
        hashAOAA["eMax"] = ["e3", e3, E3_INDICIES]
      else
        hashAOAA["eMax"] = ["e1", e1, E1_INDICIES]
        hashAOAA["eMid"] = ["e3", e3, E3_INDICIES]
      end
    else
      hashAOAA["eMin"] = ["e3", e3, E3_INDICIES]
      if sorted[1] == e1
        hashAOAA["eMid"] = ["e1", e1, E1_INDICIES]
        hashAOAA["eMax"] = ["e2", e2, E2_INDICIES]
      else
        hashAOAA["eMax"] = ["e1", e1, E1_INDICIES]
        hashAOAA["eMid"] = ["e2", e2, E2_INDICIES]
      end
    end

    hashAOAA
  end

  # calculates the AOAAs for a GOS
  def calcGOSAOAAs(buf, channel)
    e1 = calcSectionAOAA(buf, channel, E1_INDICIES[0], E1_INDICIES[1])
    e2 = calcSectionAOAA(buf, channel, E2_INDICIES[0], E2_INDICIES[1])
    e3 = calcSectionAOAA(buf, channel, E3_INDICIES[0], E3_INDICIES[1])
    [e1, e2, e3]
  end

  # calculates the AOAA of a section of a 1 channel sample (start & end index inclusive)
  def calcSectionAOAA(buf,channel, startIndex, endIndex)
    aoaa = 0
    (startIndex..endIndex).each { |x|  aoaa += (buf[x][channel]).abs() }
    aoaa / (endIndex - startIndex + 1)
  end

  # deletes uploaded files and all associated records with that file
  def deleteUploadedFile(uploadedfile)

    # delete shared copies
    uploadedfile.sharedfiles.each do |shared_file|
      shared_file.audio_file.purge
      shared_file.destroy
    end

    # delete find origin results
    FindOriginResult.where(uploadedfile: uploadedfile.id).destroy_all

    # delete attachment
    uploadedfile.audio_file.purge
    #@uploadedfile.audio_file.purge_later ASYNC

    # delete record
    uploadedfile.destroy
  end

end
