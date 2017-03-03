/* -*- c++ -*- */
/* 
 * Copyright 2017 <+YOU OR YOUR COMPANY+>.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */


#include <SynchronousLabs/downSampler_block_ctrl.hpp>
#include <uhd/convert.hpp>
#include <uhd/utils/msg.hpp>

using namespace uhd::rfnoc;

class downSampler_block_ctrl_impl : public downSampler_block_ctrl
{
	uint32_t n_val;
	uint32_t m_val;
	
public:

	static const uint32_t SR_DELTA_REG   = 192;
    //static const uint32_t SR_M_REG       = 193;
    //static const uint32_t SR_N_REG       = 194;
    //static const uint32_t SR_CONFIG_REG  = 195;
   
	
    UHD_RFNOC_BLOCK_CONSTRUCTOR(downSampler_block_ctrl)
    {
		
        uint32_t default_n = get_arg<uint32_t>("sr_n");
        printf("default_n %d\n", default_n);
        _tree->access<uint32_t>(get_arg_path("sr_n/value"))
			.add_coerced_subscriber(boost::bind(&downSampler_block_ctrl_impl::set_n, this, _1))
        ;
        uint32_t default_m = get_arg<uint32_t>("sr_m");
        printf("default_m %d\n", default_m);
        _tree->access<uint32_t>(get_arg_path("sr_m/value"))
            .add_coerced_subscriber(boost::bind(&downSampler_block_ctrl_impl::set_m, this, _1))
        ;
               
        //sr_write(SR_N_REG, 2);
		//sr_write(SR_M_REG, 1);
		//sr_write(SR_CONFIG_REG, 0);
		sr_write(SR_DELTA_REG, 0x40000000);

    }
    virtual ~downSampler_block_ctrl_impl() {};

    void set_m(uint32_t m)
    {	
		printf("sr_m %d\n", m_val);
		m_val = m;
		update_resamp_rate();
    }
    void set_n(uint32_t n)
    {		
		printf("sr_n %d\n", n_val);
		n_val = n;
		update_resamp_rate();
    }
    void update_resamp_rate()
    {	
		double tmp = 4294967296*((double)m_val/(double)n_val);
		uint32_t tmp1 = (uint32_t)tmp;
		printf("delta_reg: %X\n", tmp1);
		//sr_write(SR_N_REG, n_val);
		//sr_write(SR_M_REG, m_val);
		sr_write(SR_DELTA_REG, round((uint32_t)tmp));
    }
    
    
private:


};

UHD_RFNOC_BLOCK_REGISTER(downSampler_block_ctrl,"downSampler");
