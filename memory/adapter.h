#ifndef CPU_JUDGE_ADAPTER_H
#define CPU_JUDGE_ADAPTER_H

#include "env_iface.h"
#include <bitset>

class Adapter
{
private:
	enum status{
		STATUS_IDLE,
		STATUS_CHANNEL,
		STATUS_LENGTH,
		STATUS_DATA,
		STATUS_END
	}recv_status;
	static const int inst_width  = 72;
	std :: bitset<inst_width> inst;
	size_t recv_packet_id, recv_bit, recv_length, send_packet_id = 0;
	uint8_t recv_counter = 0;
	void feedback();
	void send(uint32_t data);
	
public:
	Adapter() : env(nullptr) {
		recv_status = STATUS_IDLE;
	}

	void setEnvironment(IEnvironment *env) { this->env = env; }

	void onRecv(std::uint8_t data);

	//TODO: You may the following settings according to the UART implementation in your CPU
	std::uint32_t getBaudrate() { return 9600; }
	serial::bytesize_t getBytesize() { return serial::eightbits; }
	serial::parity_t getParity() { return serial::parity_even; }
	serial::stopbits_t getStopBits() { return serial::stopbits_one; }

protected:
	IEnvironment *env;
};

#endif