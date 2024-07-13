import whisper

def generate_subtitles(video_path):
    model = whisper.load_model("base")
    result = model.transcribe(video_path)
    subtitles_path = video_path.replace('.mp4', '.srt')
    
    with open(subtitles_path, 'w') as f:
        for segment in result['segments']:
            f.write(f"{segment['start']} --> {segment['end']}\n")
            f.write(f"{segment['text']}\n\n")
    
    (
        ffmpeg
        .input(video_path)
        .output(video_path.replace('.mp4', '_subtitled.mp4'), vf='subtitles=' + subtitles_path)
        .run()
    )
