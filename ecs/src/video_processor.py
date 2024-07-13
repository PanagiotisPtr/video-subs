import ffmpeg

def process_video(input_path, output_path, resolution_height):
    (
        ffmpeg
        .input(input_path)
        .output(output_path, vf=f'scale=-1:{resolution_height}')
        .run()
    )
