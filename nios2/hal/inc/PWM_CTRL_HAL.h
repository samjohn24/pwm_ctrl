#ifndef PWM_CTRL_HAL_H_
#define PWM_CTRL_HAL_H_

// Basic macros
#define PWM_CTRL_SET(index, seg_mask)     IOWR(PWM_CTRL_BASE,index,seg_mask)
#define PWM_CTRL_GET(index)   	          IORD(PWM_CTRL_BASE,index)

// Register addresses
#define PWM_CTRL_CTRL_1_REG_ADDR   0x00
#define PWM_CTRL_CTRL_2_REG_ADDR   0x01
#define PWM_CTRL_CH_CTRL_REG_ADDR  0x02

// Bitfield offsets and masks

// Macros
#define PWM_CTRL_SetCounter(val)        PWM_CTRL_SET(PWM_CTRL_CTRL_1_REG_ADDR, val) 
#define PWM_CTRL_GetCounter()           PWM_CTRL_GET(PWM_CTRL_CTRL_1_REG_ADDR) 

#define PWM_CTRL_SetChEnable(mask)      PWM_CTRL_SET(PWM_CTRL_CTRL_2_REG_ADDR, mask) 
#define PWM_CTRL_GetChEnable()          PWM_CTRL_GET(PWM_CTRL_CTRL_2_REG_ADDR) 

#define PWM_CTRL_SetChDuty(ch_num, val)	PWM_CTRL_SET(PWM_CTRL_CH_CTRL_REG_ADDR+ch_num, val)
#define PWM_CTRL_GetChDuty(ch_num)	PWM_CTRL_GET(PWM_CTRL_CH_CTRL_REG_ADDR+ch_num)

#endif /*PWM_CTRL_HAL_H_*/
