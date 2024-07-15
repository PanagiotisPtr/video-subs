import ffmpeg
import whisper
from convert_subs import reformat_srt


def generate_subtitles(video_path):
    print("loading model")
    model = whisper.load_model("large-v3",  device="cuda")
    print("transcribing video")
    result = model.transcribe(video_path)
    subtitles_path = video_path.replace('.mp4', '.srt')
    processed_subtitles_path = video_path.replace('.mp4', '_processed.srt')

    print("writing subs file")
    with open(subtitles_path, 'w') as f:
        for segment in result['segments']:
            f.write(f"{segment['start']} --> {segment['end']}\n")
            f.write(f"{segment['text']}\n\n")

    print("formatting subtitles")
    reformat_srt(subtitles_path, processed_subtitles_path)

    print("generating output video")
    (
        ffmpeg
        .input(video_path)
        .output(
            video_path.replace('.mp4', '_subtitled.mp4'),
            vf='subtitles=' + processed_subtitles_path,
            vcodec='h264_nvenc',
            acodec='copy'
        )
        .run()
    )
