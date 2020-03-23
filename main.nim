import strformat
import src/wav

let wave = wav.readWave("test.wav")

let slices = wav.divideBySilence(wave, 0.078, 2)

var cnt = 0
for i in slices:
    wav.writeWave(fmt"out{cnt}.wav", i)

    cnt += 1