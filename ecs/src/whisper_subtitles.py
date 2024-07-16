import ffmpeg
import whisper
from datetime import timedelta


def format_time(seconds):
    delta = timedelta(seconds=seconds)
    total_seconds = int(delta.total_seconds())
    milliseconds = int(delta.microseconds / 1000)
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours:02}:{minutes:02}:{seconds:02},{milliseconds:03}"


def generate_subtitles(video_path, output_path):
    print("loading model")
    model = whisper.load_model("large-v3",  device="cuda")
    print("transcribing video")
    result = model.transcribe(video_path)
    subtitles_path = video_path.replace('.mp4', '.srt')

    print("writing subs file")
    with open(subtitles_path, 'w') as f:
        for idx, segment in enumerate(result['segments'], start=1):
            start_time = format_time(segment['start'])
            end_time = format_time(segment['end'])
            text = segment['text'].strip()

            f.write(f"{idx}\n")
            f.write(f"{start_time} --> {end_time}\n")
            f.write(f"{text}\n\n")

    print("generating output video at output path: ", output_path)
    (
        ffmpeg
        .input(video_path)
        .output(
            output_path,
            vf='subtitles=' + subtitles_path,
            vcodec='h264_nvenc',
            acodec='copy'
        )
        .run()
    )

    return subtitles_path
