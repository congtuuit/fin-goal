import os
import wave
import struct
import math

os.makedirs('assets/audio', exist_ok=True)

def generate_wav(filename, freq=440.0, duration=0.5):
    sample_rate = 44100
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for i in range(int(duration * sample_rate)):
            # simple beep with decay
            decay = max(0, 1 - (i / (duration * sample_rate)))
            value = int(32767.0 * 0.5 * decay * math.sin(2.0 * math.pi * freq * i / sample_rate))
            w.writeframes(struct.pack('<h', value))

generate_wav('assets/audio/dice_roll.wav', freq=400, duration=0.2)
generate_wav('assets/audio/payday.wav', freq=800, duration=0.6)
generate_wav('assets/audio/card_flip.wav', freq=200, duration=0.1)
generate_wav('assets/audio/success.wav', freq=600, duration=0.4)
print("Audio generated")
