module ApplicationHelper
  L = 1020

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
    file_path = "#{Dir.tmpdir}/#{uploadedfile.fileName}"
    File.open(file_path, 'wb') do |file|
      file.write(uploadedfile.audio_file.download)
    end

    # open tmp file
    og_file = RubyAudio::Sound.open(file_path)

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
    RubyAudio::Sound.open(file_path) do |file|

      gosIndex = 0
      while file.read(buf) != 0
        puts "---------GOS " + gosIndex.to_s + "----------"

        if buf.real_size == L
          puts buf[0][0].to_s + ", " + buf[0][1].to_s

          e1 = calcSectionAOAA(buf, 0, 0, (L/3 - 1))
          e2 = calcSectionAOAA(buf, 0, (L/3), (2*L/3 - 1))
          e3 = calcSectionAOAA(buf, 0, (2*L/3), (L - 1))

          hashAOAA = sortAOAAs(e1, e2, e3)

          pp "E1: " + e1.to_s
          pp "E2: " + e2.to_s
          pp "E3: " + e3.to_s

          pp "eMin: " + hashAOAA["eMin"].to_s
          pp "eMid: " + hashAOAA["eMid"].to_s
          pp "eMax: " + hashAOAA["eMax"].to_s
        else
          pp "GOS too small to embed watermark"
        end

        puts "----------------------"
        gosIndex += 1
      end

    end

    uploadedfile.audio_file.download
  end

  def sortAOAAs(e1, e2, e3)
    sorted = [e1,e2,e3].sort

    hashAOAA = Hash.new
    if sorted[0] == e1
      hashAOAA["eMin"] = ["e1", e1]
      if sorted[1] == e2
        hashAOAA["eMid"] = ["e2", e2]
        hashAOAA["eMax"] = ["e3", e3]
      else
        hashAOAA["eMax"] = ["e2", e2]
        hashAOAA["eMid"] = ["e3", e3]
      end
    elsif sorted[0] == e2
      hashAOAA["eMin"] = ["e2", e2]
      if sorted[1] == e1
        hashAOAA["eMid"] = ["e1", e1]
        hashAOAA["eMax"] = ["e3", e3]
      else
        hashAOAA["eMax"] = ["e1", e1]
        hashAOAA["eMid"] = ["e3", e3]
      end
    else
      hashAOAA["eMin"] = ["e3", e3]
      if sorted[1] == e1
        hashAOAA["eMid"] = ["e1", e1]
        hashAOAA["eMax"] = ["e2", e2]
      else
        hashAOAA["eMax"] = ["e1", e1]
        hashAOAA["eMid"] = ["e2", e2]
      end
    end

    hashAOAA
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
