#include "wavloader.hpp"

#include <limits>
#include <memory>

#include <SDL2/SDL.h>

#include "base/log.hpp"

namespace blunted {

WAVLoader::WAVLoader() : Loader<SoundBuffer>() {}
WAVLoader::~WAVLoader() {}

void WAVLoader::Load(const std::string& filename,
                     boost::intrusive_ptr<Resource<SoundBuffer>> resource) {
  SDL_AudioSpec spec{};
  Uint8* samples = nullptr;
  Uint32 byteCount = 0;
  if (!SDL_LoadWAV(filename.c_str(), &spec, &samples, &byteCount)) {
    Log(e_FatalError, "WAVLoader", "Load", "Could not load " + filename + ": " + SDL_GetError());
    return;
  }
  std::unique_ptr<Uint8, decltype(&SDL_FreeWAV)> ownedSamples(samples, SDL_FreeWAV);
  const int bits = SDL_AUDIO_BITSIZE(spec.format);
  if ((spec.format != AUDIO_U8 && spec.format != AUDIO_S16LSB) ||
      (spec.channels != 1 && spec.channels != 2) || spec.freq <= 0 || byteCount == 0 ||
      byteCount > static_cast<Uint32>((std::numeric_limits<int>::max)()) ||
      byteCount % (spec.channels * (bits / 8)) != 0) {
    Log(e_FatalError, "WAVLoader", "Load",
        "Could not load " + filename + ": expected nonempty mono/stereo 8-bit or 16-bit PCM");
    return;
  }
  auto data = std::make_unique<WavData>();
  data->data = new unsigned char[byteCount];
  memcpy(data->data, samples, byteCount);
  data->size = static_cast<int>(byteCount);
  data->channels = spec.channels;
  data->bits = bits;
  data->frequency = spec.freq;
  resource->GetResource()->SetData(data.release());
}

}  // namespace blunted
