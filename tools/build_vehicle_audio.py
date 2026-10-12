"""Generate original road/engine loops, no downloaded recordings or dependencies."""
from pathlib import Path
import math
import random
import struct
import wave

root = Path(__file__).resolve().parents[1]
destination = root / "demo/audio"
destination.mkdir(exist_ok=True)
rate = 22050
for name, combustion, seed in [("car_road", 90.0, 42), ("truck_road", 55.0, 84), ("motorcycle_engine", 50.0, 126)]:
    rng = random.Random(seed)
    low = 0.0
    tire = 0.0
    samples = []
    for frame in range(rate * 2):
        t = frame / rate
        noise = rng.uniform(-1, 1)
        low += (noise - low) * 0.055
        tire += (noise - tire) * 0.42
        engine = sum(math.sin(math.tau * combustion * harmonic * t) / harmonic for harmonic in range(1, 7))
        pulse = 0.82 + 0.18 * math.sin(math.tau * 11 * t)
        air = (tire - low) * 0.015 + low * 0.09
        if name == "motorcycle_engine":
            air = 0.0
        sample = engine * pulse * (0.25 if name == "truck_road" else 0.20) + air
        samples.append(int(max(-0.9, min(0.9, sample)) * 32767))
    with wave.open(str(destination / (name + ".wav")), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(struct.pack("<" + "h" * len(samples), *samples))
