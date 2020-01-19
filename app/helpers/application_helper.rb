module ApplicationHelper
  L = 1020
  E1_INDICIES = [0, (L/3 - 1)]
  E2_INDICIES = [(L/3), (2*L/3 - 1)]
  E3_INDICIES = [(2*L/3), (L - 1)]

      def find_leak_source(original_file, leaker_file)

    pp "*******************************************"
    snd = RubyAudio::Sound.open(leaker_file)
    pp "channels: " + snd.info.channels.to_s
    pp "sample rate: " + snd.info.samplerate.to_s
    pp "length: " + snd.info.length.to_s

    # TODO find leak origin

    "John Doe"
  end



  def embed_watermark(uploadedfile)

    # Download the uploadedfile tmp dir
    og_file_path = "#{Dir.tmpdir}/#{uploadedfile.fileName}"
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

    pp "******************OG File*************************"
    pp "channels: " + channelCount.to_s
    pp "sample rate: " + sampleRate.to_s
    pp "frames: " + frames.to_s
    pp "sections: " + sections.to_s
    pp "length: " + lengthS.to_s


    buf = RubyAudio::Buffer.new("float", L, channelCount)
    out = nil
    out_file_path = "#{Dir.tmpdir}/#{uploadedfile.fileName + '_watermarked'}"
    RubyAudio::Sound.open(og_file_path) do |file|
      out = RubyAudio::Sound.open(out_file_path, 'w', file.info.clone) if out.nil?


      gosIndex = 0
      while file.read(buf) != 0
        puts "---------GOS " + gosIndex.to_s + "----------"

        if buf.real_size == L
          puts buf[0][0].to_s + ", " + buf[0][1].to_s

          channel = 0
          embed_bit = 1

          # calculate AOAAs
          gosAOAAs = calcGOSAOAAs(buf, channel)

          # sort AOAAs
          hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])

          pp "eMin: " + hashAOAA["eMin"].to_s
          pp "eMid: " + hashAOAA["eMid"].to_s
          pp "eMax: " + hashAOAA["eMax"].to_s

          a,b = calcA_B(hashAOAA)

          if a >= b
            pp "Initial GOS Value: 1"
          else
            pp "Initial GOS Value: 0"
          end

          thd1 = calcThd1(hashAOAA, 0.05)

          if embed_bit == 1
            pp "Embedding 1 bit"
            satisfiesCondition = (a - b) >= thd1
            pp "A - B >= Thd1 | " + satisfiesCondition.to_s
            pp (a - b).to_s + " >=? " + thd1.to_s

            if satisfiesCondition
              pp "Condition Satisfied, no operation needed."
            else
              pp "Scaling amplitudes"
              pp "OG     -> " + buf[3].to_s
              embed_1(buf,channel,hashAOAA, a, b, thd1)
              pp "scaled -> " + buf[3].to_s
            end

          else
            # TODO embed 0
          end

        else
          pp "GOS too small to embed watermark"
        end
        out.write(buf)
        puts "----------------------"
        gosIndex += 1
      end
      out.close if out
    end

    #uploadedfile.audio_file.download
    out_file_path
  end


  def embed_1(buf,channel,hashAOAA, a, b, thd1)
    d = 0.05
    delta = (thd1 - (a - b)) / 3
    w_up = 1 + (delta / hashAOAA["eMax"][1])
    w_down = 1 - (delta / hashAOAA["eMid"][1])
    w_delta = 0.05

    count = 0
    while !(a - b >= thd1)
      count += 1
      buf_clone = buf.map(&:clone)

      # scale up eMax
      scaleSection(buf_clone, channel, hashAOAA["eMax"][2][0], hashAOAA["eMax"][2][1], w_up)

      # scale down eMid
      scaleSection(buf_clone, channel, hashAOAA["eMid"][2][0], hashAOAA["eMid"][2][1], w_down)

      # reevaluate A & B
      gosAOAAs = calcGOSAOAAs(buf_clone, channel)
      hashAOAA = sortAOAAs(gosAOAAs[0], gosAOAAs[1], gosAOAAs[2])
      a,b = calcA_B(hashAOAA)
      thd1 = calcThd1(hashAOAA, d)

      # increment w
      w_up += w_delta
      w_down -= w_delta

    end

    pp "count: " + count.to_s

    # copy back to OG buffer
    buf_clone.each_with_index do |item, index|
      buf[index] = item
    end

  end

  def scaleSection(buf, channel, startIndex, endIndex, w)
    (startIndex..endIndex).each do |x|
      buf[x][channel] = w * buf[x][channel]
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
    e2 = calcSectionAOAA(buf, channel, E2_INDICIES[0], E2_INDICIES[0])
    e3 = calcSectionAOAA(buf, channel, E3_INDICIES[0], E3_INDICIES[0])
    [e1, e2, e3]
  end

  # calculates the AOAA of a section of a 1 channel sample (start & end index inclusive)
  def calcSectionAOAA(buf,channel, startIndex, endIndex)
    aoaa = 0
    (startIndex..endIndex).each { |x|  aoaa += (buf[x][channel]).abs() }
    aoaa / (endIndex - startIndex + 1)
  end

  def watermark()

    watermark = SecureRandom.random_bytes(16).unpack('b128')[0]
    pp "Key: " + watermark.to_s

    watermark_sync = concat_sync_code(watermark)

    pp "Key: " + watermark_sync

    return nil
  end

  def concat_sync_code(watermark)
    sync_codes = %w(1010101011001101 1111101110101100 0000000101111111 1010010011010101 1100010001100010 1110100110000010 0100001101111111 1101100111100110 1000011011011111 0111001000000011 1111101011100010 0010101100001100 0111000000110110 1000001110101000 1101100011001011 0000101010100110 1111101010001010 1001101000100111 1110101100001001 0001000001101010)
    sync_codes.sample + watermark
  end

end
