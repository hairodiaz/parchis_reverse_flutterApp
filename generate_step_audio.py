#!/usr/bin/env python3
"""
🎵 GENERADOR DE AUDIO PARA PASOS DE FICHA - PARCHIS REVERSE
Crea un sonido corto y preciso para simular los pasos de la ficha
"""

import numpy as np
import scipy.io.wavfile as wav
import os

def generate_step_sound():
    """Genera un sonido de 'paso' corto y claro"""
    
    # Configuración del audio
    sample_rate = 44100  # Hz
    duration = 0.12      # 120ms - perfecto para pasos rápidos
    
    # Generar tiempo
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    
    # Crear sonido compuesto (mezcla de frecuencias para sonido más rico)
    frequency1 = 800   # Frecuencia principal (click agudo)
    frequency2 = 400   # Frecuencia secundaria (cuerpo del sonido)
    frequency3 = 1200  # Frecuencia alta (brillo)
    
    # Generar ondas
    wave1 = np.sin(2 * np.pi * frequency1 * t) * 0.6  # Principal
    wave2 = np.sin(2 * np.pi * frequency2 * t) * 0.3  # Cuerpo
    wave3 = np.sin(2 * np.pi * frequency3 * t) * 0.1  # Brillo
    
    # Combinar ondas
    audio = wave1 + wave2 + wave3
    
    # Crear envolvente ADSR (Attack, Decay, Sustain, Release)
    attack_samples = int(0.01 * sample_rate)  # 10ms ataque rápido
    decay_samples = int(0.02 * sample_rate)   # 20ms decaimiento
    sustain_samples = int(0.04 * sample_rate) # 40ms sostenido
    release_samples = len(audio) - attack_samples - decay_samples - sustain_samples
    
    envelope = np.ones_like(audio)
    
    # Ataque (0 a 1)
    envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    
    # Decaimiento (1 a 0.7)
    envelope[attack_samples:attack_samples + decay_samples] = np.linspace(1, 0.7, decay_samples)
    
    # Sostenido (0.7)
    envelope[attack_samples + decay_samples:attack_samples + decay_samples + sustain_samples] = 0.7
    
    # Release (0.7 a 0)
    envelope[attack_samples + decay_samples + sustain_samples:] = np.linspace(0.7, 0, release_samples)
    
    # Aplicar envolvente
    audio = audio * envelope
    
    # Normalizar audio (evitar clipping)
    audio = audio / np.max(np.abs(audio)) * 0.8
    
    # Convertir a 16-bit PCM
    audio_16bit = (audio * 32767).astype(np.int16)
    
    return audio_16bit, sample_rate

def save_audio(audio_data, sample_rate, filename):
    """Guarda el audio como archivo WAV"""
    wav.write(filename, sample_rate, audio_data)
    print(f"✅ Audio generado: {filename}")
    print(f"📊 Duración: {len(audio_data) / sample_rate:.3f} segundos")
    print(f"🔊 Sample Rate: {sample_rate} Hz")
    print(f"📁 Tamaño: {os.path.getsize(filename)} bytes")

def convert_to_mp3(wav_file, mp3_file):
    """Convierte WAV a MP3 usando ffmpeg (si está disponible)"""
    try:
        import subprocess
        cmd = [
            'ffmpeg', 
            '-i', wav_file,
            '-codec:a', 'libmp3lame',
            '-b:a', '128k',
            '-y',  # Sobrescribir si existe
            mp3_file
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ Convertido a MP3: {mp3_file}")
            # Eliminar WAV temporal
            os.remove(wav_file)
            return True
        else:
            print(f"⚠️ Error convertiendo a MP3: {result.stderr}")
            print(f"📁 Archivo WAV disponible: {wav_file}")
            return False
            
    except FileNotFoundError:
        print("⚠️ ffmpeg no encontrado. Usando archivo WAV.")
        print("💡 Para MP3, instala ffmpeg: https://ffmpeg.org/download.html")
        return False

def main():
    """Función principal"""
    print("🎵 GENERADOR DE AUDIO PARA PASOS DE FICHA")
    print("==========================================")
    
    # Generar audio
    print("🔧 Generando sonido de paso...")
    audio_data, sample_rate = generate_step_sound()
    
    # Rutas de archivos
    wav_file = "pop_ficha_short.wav"
    mp3_file = "pop_ficha_short.mp3"
    
    # Guardar como WAV
    save_audio(audio_data, sample_rate, wav_file)
    
    # Intentar convertir a MP3
    print("\n🔄 Intentando convertir a MP3...")
    mp3_success = convert_to_mp3(wav_file, mp3_file)
    
    if mp3_success:
        print(f"\n🎯 ¡LISTO! Copia {mp3_file} a:")
        print("   assets/audio/effects/pop_ficha_short.mp3")
    else:
        print(f"\n🎯 ¡LISTO! Convierte {wav_file} a MP3 y cópialo a:")
        print("   assets/audio/effects/pop_ficha_short.mp3")
    
    print("\n📝 ESPECIFICACIONES DEL AUDIO:")
    print("   • Duración: 120ms (perfecto para pasos rápidos)")
    print("   • Frecuencias: 400Hz + 800Hz + 1200Hz (sonido rico)")
    print("   • Envolvente ADSR (ataque rápido, release suave)")
    print("   • Normalizado a 80% para evitar clipping")
    print("   • 16-bit PCM, 44.1kHz")
    
    print("\n🚀 SIGUIENTE PASO:")
    print("   Actualiza el código para usar pop_ficha_short.mp3")

if __name__ == "__main__":
    main()