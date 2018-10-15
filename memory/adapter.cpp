#include "adapter.h"
#include <iostream>
#include <vector>
#include <bitset>
// TODO: Do something when you receive a byte from your CPU
//
// You can access the memory like this:
//    env->ReadMemory(address)
//    env->WriteMemory(address, data, mask)
// where
//   <address>: the address you want to read from / write to, must be aligned to 4 bytes
//   <data>:    the data you want to write to the <address>
//   <mask>:    (in range [0x0-0xf]) the bit <i> indicates that you want to write byte <i> of <data> to address <address>+i
//              for example, if you want to write 0x2017 to address 0x1002, you can write
//              env.WriteMemory(0x1000, 0x20170000, 0b1100)
// NOTICE that the memory is little-endian
//
// You can also send data to your CPU by using:
//    env->UARTSend(data)
// where <data> can be a string or vector of bytes (uint8_t)

void Adapter :: feedback(){
	// read request packet format: (MSB -> LSB) (length = 4 byte)
    //  0 addr
    // write request packet format:
    //  1 length(in byte) addr data
    // read response packet format:
    //  data
	std :: vector<uint8_t> bytes;
	bytes.clear();
	for (int i = 0; i < recv_bit; i += 8){
		uint8_t byte = 0;
		for (int j = i; j < i + 8; j++)
			byte = (byte << 1) | inst[j];
		bytes.push_back(byte);
	}

	if (bytes.size() == 5 && bytes[4] == 0){
		uint32_t addr = (bytes[0]) | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
		uint32_t data = env->ReadMemory(addr);
		send(data);
	}else if (bytes.size() == 9){
		uint32_t data = (bytes[0]) | (bytes[2] << 8) | (bytes[3] << 16) | (bytes[3] << 24);
		uint32_t addr = (bytes[4]) | (bytes[5] << 8) | (bytes[6] << 16) | (bytes[7] << 24);
		env->WriteMemory(addr, data, bytes[8] & (0x0f));
	}
}

void Adapter :: send(uint32_t data){
	/*
	{100, packet_id}
	{101  00000}
	{110, length}
	{0, data[1]}, {0, data[2]}, {0, data[3]}... //data[...|3|2]|1]
	{111, packet_id}
    */
	std :: vector<uint8_t> bytes;
	send_packet_id++;
	bytes.push_back(uint8_t((4 << 5) | (send_packet_id & 0x1f)));
	bytes.push_back(uint8_t((5 << 5) | 0));
	bytes.push_back(uint8_t((6 << 5) | 4));	
	bytes.push_back(uint8_t((data >>  0) & 0x7f));
	bytes.push_back(uint8_t((data >>  7) & 0x7f));
	bytes.push_back(uint8_t((data >> 14) & 0x7f));
	bytes.push_back(uint8_t((data >> 21) & 0x7f));
	bytes.push_back(uint8_t((data >> 28) & 0x7f));
	bytes.push_back(uint8_t((7 << 5) | (send_packet_id & 0x1f)));
	env->UARTSend(bytes);
}

void Adapter :: onRecv(std::uint8_t data){
	// read request packet format: (MSB -> LSB) (length = 4 byte)
    //  0 addr
    // write request packet format:
    //  1 length(in byte) addr data
    // read response packet format:
    //  data
    /*
	{100, packet_id}
	{101  00000}
	{110, length}
	{0, data[1]}, {0, data[2]}, {0, data[3]}... //data[...|3|2]|1]
	{111, packet_id}
    */

    uint8_t op = data >> 5;

    switch (recv_status) {
    	case STATUS_IDLE : {
    		if (op == 4){
    			recv_packet_id = data & 0x1f;
    			recv_bit = 0;
    			recv_length = 0;
    			recv_status = STATUS_CHANNEL;
    		}else{
    			recv_status = STATUS_IDLE;
    		}
    		break;
    	}
    	case STATUS_CHANNEL : {
    		if (op == 5){
    			recv_status = STATUS_LENGTH;
    		}else{
    			recv_status = STATUS_IDLE;
    		}
    		break;
    	}
    	case STATUS_LENGTH : {
    		if (op == 6){
    			recv_length = (data & 0x1f) * 8;
    			recv_status = STATUS_DATA;
    		}else{
    			recv_status = STATUS_IDLE;
    		}
    		break;
    	}
    	case STATUS_DATA : {
    		std :: bitset<8> data_array(data);
    		if (data_array[7] == 0){
    			for (int i = 0; i < 7 && recv_bit < recv_length; i++)
    				inst[recv_bit++] = data_array[i];
    			if (recv_bit == recv_length)
    				recv_status = STATUS_END;
    		}else{
    			recv_status = STATUS_IDLE;
    		}
    		break;
    	}
    	case STATUS_END : {
    		if (op == 7){
    			size_t packet_id_now = data & 0x1f;
    			if (recv_packet_id == packet_id_now)
    				feedback();
    			recv_status = STATUS_IDLE;
    		}else{
    			recv_status = STATUS_IDLE;
    		}
    		break;
    	}
    }
}