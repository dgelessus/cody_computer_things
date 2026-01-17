#!/usr/bin/env -S uv run --script
# -*- coding: utf-8 -*-
# /// script
# dependencies = ["pyserial"]
# ///

# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2025 dgelessus
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""Send/receive BASIC and machine code programs to/from the Cody Computer over serial.

This script configures the serial port appropriately
and waits as necessary between lines when sending BASIC programs.
"""

import argparse
import io
import os.path
import shutil
import sys

import serial

def is_asm_extension(ext):
	return ext.lower() in {".asm", ".ca65", ".s", ".tass"}

def data_type_from_file_extension(ext):
	if ext.lower() == ".bas":
		return "basic"
	else:
		return "data"

def open_serial_port(port):
	"""Open the given serial port with the appropriate settings for the Cody Computer's UARTs."""
	
	return serial.Serial(
		port,
		baudrate=19200,
		bytesize=serial.EIGHTBITS,
		parity=serial.PARITY_NONE,
		stopbits=serial.STOPBITS_ONE,
		exclusive=True,
	)

def send_basic_source(basic_stream, ser, basic_prompt_character=b"?"):
	"""Send Cody BASIC source code line by line over the given serial port."""
	
	print('Run "LOAD 1, 0" on the Cody Computer...')
	
	if basic_prompt_character is not None:
		prompt = ser.read(1)
		if prompt != basic_prompt_character:
			print(f"Received unexpected prompt character from the Cody Computer: {prompt!r}", file=sys.stderr, flush=True)
	
	for line in basic_stream:
		# accept CRLF, LF and CR line endings
		if line.endswith(b"\r\n"):
			line = line[:-2]
		elif line.endswith(b"\n") or line.endswith(b"\r"):
			line = line[:-1]

		if not line:
			# Skip empty lines to avoid accidentally terminating the program early.
			continue
		
		ser.write(line)
		ser.write(b"\n")
		ser.flush()
		
		# Progress indication on stdout...
		print(str(line, encoding="ascii", errors="replace"), flush=True)
		
		if basic_prompt_character is not None:
			prompt = ser.read(1)
			if prompt != basic_prompt_character:
				print("Received unexpected prompt character from the Cody Computer: {prompt!r}", file=sys.stderr, flush=True)
	
	# Signal the end of the BASIC program using an empty line.
	ser.write(b"\n")
	ser.flush()

def main():
	ap = argparse.ArgumentParser(
		description=__doc__,
		add_help=False,
	)
	
	ap.add_argument("--help", action="help", help="Show this help message and exit.")
	ap.add_argument("-p", "--port", required=True, help="The serial port to which the Cody Computer is connected.")
	ap.add_argument("-t", "--type", choices=["basic", "data"], help="The type of data to send. When sending a BASIC program, this script will wait after each line as necessary rather than sending all data at once. By default, the type is determined automatically based on the file extension.")
	ap.add_argument("-f", "--force", action="store_true", help="Overwrite output file if it exists.")
	ap.add_argument("action", choices=["send", "receive"], help="The communication direction.")
	ap.add_argument("file", help="The local file to send or to which to write the received data, use '-' for stdin/stdout.")
	
	args = ap.parse_args()

	file_is_stream = args.file == "-"
	if args.action == "send":
		if args.type is None:
			if file_is_stream:
				print("When sending from stdin you need to pass the data type explicitly - rerun with --type=basic or --type=data.", file=sys.stderr)
				sys.exit(1)

			_, ext = os.path.splitext(args.file)
			
			if is_asm_extension(ext):
				print("An assembly source file cannot be sent directly to the Cody Computer - assemble it first and send the assembled binary file.", file=sys.stderr)
				print("(If you really want to send the assembly source file as text, rerun with --type=data.)", file=sys.stderr)
				sys.exit(1)
			
			args.type = data_type_from_file_extension(ext)
		
		with sys.stdin.buffer if file_is_stream else io.open(args.file, "rb") as f:
			with open_serial_port(args.port) as ser:
				if args.type == "basic":
					send_basic_source(f, ser)
				elif args.type == "data":
					shutil.copyfileobj(f, ser)
				else:
					print(f"Invalid data type: {args.type!r}", file=sys.stderr)
					sys.exit(2)
	elif args.action == "receive":
		if not file_is_stream and not args.force and os.path.exists(args.file):
			answer = input(f"Output file {args.file!r} already exists. Overwrite? ")
			if answer.strip().lower() != "y":
				sys.exit(1)
		
		print("Press Ctrl+C once the file has been fully sent.", file=sys.stderr, flush=True)
		
		with sys.stdout.buffer if file_is_stream else io.open(args.file, "wb") as f:
			with open_serial_port(args.port) as ser:
				shutil.copyfileobj(ser, f, 1)
	else:
		print(f"Invalid action: {args.action!r}", file=sys.stderr)
		sys.exit(2)

if __name__ == "__main__":
	sys.exit(main())
