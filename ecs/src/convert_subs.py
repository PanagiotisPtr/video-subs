import re
import sys


def convert_to_srt_time_format(time_string):
    parts = time_string.split('.')
    seconds = int(parts[0])
    milliseconds = int(float(f"0.{parts[1]}") * 1000) if len(parts) > 1 else 0
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    seconds = seconds % 60
    return f"{hours:02}:{minutes:02}:{seconds:02},{milliseconds:03}"


def reformat_srt(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as infile:
        content = infile.read()

    # Split content by empty lines to get each subtitle block
    blocks = content.strip().split('\n\n')

    formatted_blocks = []
    for i, block in enumerate(blocks):
        # Split each block by lines
        lines = block.strip().split('\n')

        if len(lines) >= 2:
            # Extract the timing line
            time_line = lines[0].strip()
            start_time, end_time = time_line.split(' --> ')

            # Convert times to correct format
            start_time = convert_to_srt_time_format(start_time)
            end_time = convert_to_srt_time_format(end_time)

            # Construct the corrected time line
            corrected_time_line = f"{start_time} --> {end_time}"

            # Join the lines back together, adding the index
            formatted_block = f"{
                i+1}\n{corrected_time_line}\n" + '\n'.join(lines[1:])
            formatted_blocks.append(formatted_block)

    # Join all formatted blocks
    formatted_content = '\n\n'.join(formatted_blocks)

    # Write to the output file
    with open(output_path, 'w', encoding='utf-8') as outfile:
        outfile.write(formatted_content)
