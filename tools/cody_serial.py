# -*- coding: utf-8 -*-

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

basic_prompt_character = b"?"

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

def send_basic_source(basic_stream, ser):
	"""Send Cody BASIC source code line by line over the given serial port."""
	
	print('Run "LOAD 1, 0" on the Cody Computer...')
	
	prompt = ser.read(1)
	if prompt != basic_prompt_character:
		sys.stderr.write("Received unexpected prompt character from the Cody Computer: " + repr(prompt) + "\n")
	
	for line in basic_stream:
		if line == b"\n":
			# Skip empty lines to avoid accidentally terminating the program early.
			continue
		
		ser.write(line)
		
		# Progress indication on stdout...
		sys.stdout.write(".")
		sys.stdout.flush()
		
		prompt = ser.read(1)
		if prompt != basic_prompt_character:
			sys.stderr.write("Received unexpected prompt character from the Cody Computer: " + repr(prompt) + "\n")
	
	# Signal the end of the BASIC program using an empty line.
	ser.write(b"\n")
	# Print newline after progress indicator.
	print("")

def main():
	ap = argparse.ArgumentParser(
		description=__doc__,
		add_help=False,
	)
	
	ap.add_argument("--help", action="help", help="Show this help message and exit.")
	ap.add_argument("-p", "--port", required=True, help="The serial port to which the Cody Computer is connected.")
	ap.add_argument("-t", "--type", choices=["basic", "data"], help="The type of data to send. When sending a BASIC program, this script will wait after each line as necessary rather than sending all data at once. By default, the type is determined automatically based on the file extension.")
	ap.add_argument("action", choices=["send", "receive"], help="The communication direction.")
	ap.add_argument("file", help="The local file to send or to which to write the received data.")
	
	args = ap.parse_args()
	
	if args.action == "send":
		if args.type is None:
			_, ext = os.path.splitext(args.file)
			
			if is_asm_extension(ext):
				sys.stderr.write("An assembly source file cannot be sent directly to the Cody Computer - assemble it first and send the assembled binary file.\n")
				sys.stderr.write("(If you really want to send the assembly source file as text, rerun with --type=data.)\n")
				sys.exit(1)
			
			args.type = data_type_from_file_extension(ext)
		
		with io.open(args.file, "rb") as f:
			with open_serial_port(args.port) as ser:
				if args.type == "basic":
					send_basic_source(f, ser)
				elif args.type == "data":
					shutil.copyfileobj(f, ser)
				else:
					sys.stderr.write("Invalid data type: " + repr(args.type) + "\n")
					sys.exit(2)
	elif args.action == "receive":
		if os.path.exists(args.file):
			sys.stderr.write("Output file " + repr(args.file) + " already exists. Overwrite? ")
			sys.stderr.flush()
			answer = sys.stdin.readline()
			if answer.strip().lower() != "y":
				sys.exit(1)
		
		sys.stderr.write("Press Ctrl+C once the file has been fully sent.\n")
		sys.stderr.flush()
		
		with io.open(args.file, "wb") as f:
			with open_serial_port(args.port) as ser:
				shutil.copyfileobj(ser, f, 1)
	else:
		sys.stderr.write("Invalid action: " + repr(args.action) + "\n")
		sys.exit(2)

if __name__ == "__main__":
	sys.exit(main())
