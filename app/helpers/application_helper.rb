module ApplicationHelper

  def find_leak_source(original_file, leaker_file)

    pp "*******************************************"
    snd = RubyAudio::Sound.open(leaker_file)
    pp "channels: " + snd.info.channels.to_s
    pp "sample rate: " + snd.info.samplerate.to_s
    pp "length: " + snd.info.length.to_s

    # TODO find leak origin

    "John Doe"
  end

  def embed_watermark(file)

    file
  end

end
