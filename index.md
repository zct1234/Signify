## Signify面试
### 基于51单片机的温度读取和控制器
```c
#include <reg52.h>
#include <STC12C.h>
#include <intrins.h>              

sbit LCD_RS=P3^2;    /*LCD寄存器选择信号*/
sbit LCD_R_W=P3^3;   /*LCD读写信号*/
sbit LCD_E=P3^4;     /*LCD片选信号*/

//变量类型标识的宏定义
#define Uchar unsigned char
#define Uint unsigned int
#define uchar unsigned char
#define uint unsigned int

/* 定义命令 */
#define ISP_IAP_BYTE_READ	0x01        /*  字节读数据存储区   */
#define ISP_IAP_BYTE_PROGRAM    0x02        /*  字节编程数据存储区 */
#define ISP_IAP_SECTOR_ERASE    0x03        /*  扇区擦除数据存储区 */

/* 定义Flash 操作等待时间 */
#define ENABLE_ISP                    0x84
#define DATA_FLASH_START_ADDRESS      0x2800

typedef     unsigned char   INT8U;      /* 8 bit 无符号整型  */
typedef     unsigned int    INT16U;     /* 16 bit 无符号整型 */
#define	    DELAY_CONST     60000

/* 定义常量 */
#define ERROR   0
#define OK      1

// 控制引脚定义
sbit RS=P3^2;
sbit RW=P3^3; 
sbit Elcm=P3^4;  

sbit ON_OFF=P3^7;

sbit KEY_ON_OFF=P1^3;
sbit KEY_DEC=P1^4;
sbit KEY_ADD=P1^5;
sbit PC=P1^7;
sbit LED_Red = P1^1;
sbit LED_Yellow = P1^2;
sbit LED_Green = P1^0;

unsigned int data AdcMem;
unsigned char data tempAdc;
unsigned char lcd_data[5];
unsigned int i,k,j;
unsigned int PWM;
unsigned char disp_bool;
unsigned char tempC;
unsigned char overflag;
unsigned char changeflag;

#define DataPort P2                // 数据端口
#define Busy    0x80
#define uchar unsigned char
#define uint unsigned int
#define ulong unsigned long
#define _Nop() _nop_()

unsigned int thinkness;

char idata word_storeroom[]=
{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}; 

void Delay400Ms(void);
void Delay5Ms(void);
void WaitForEnable( void );
void LcdWriteData( char dataW );
void LcdWriteCommand( Uchar CMD,Uchar AttribC );
void LcdReset( void );
void Display( Uchar dd );
void DispOneChar(Uchar x,Uchar y,Uchar Wdata);
//void ePutstr(Uchar x,Uchar y, Uchar code *ptr);
void SmallCur(void);
void BigCur(void);
void send(uchar i);

void Disp_XY( char posx,char posy) {
    uchar temp;
    temp = posx %40;// & 0x07;
    posy &= 0x01;
    if ( posy==1)  {temp |= 0x40;}
    temp |= 0x80;
    LcdWriteCommand(temp,1);
}

/*=======================================================
按指定位置显示数出一个字符
=======================================================*/
void DispOneChar(Uchar x,Uchar y,Uchar Wdata) {

    Disp_XY( x, y );                // 定位显示地址
    LcdWriteData( Wdata );          // 写字符
}

/*=======================================================
初始化程序, 必须按照产品资料介绍的初始化过程进行
=======================================================*/
void LcdReset( void ) {
       LcdWriteCommand( 0x38, 0);         // 显示模式设置(不检测忙信号)
        Delay5Ms();
    LcdWriteCommand( 0x38, 0);            // 共三次
        Delay5Ms();
    LcdWriteCommand( 0x38, 0);
        Delay5Ms();

    LcdWriteCommand( 0x38, 1);            // 显示模式设置(以后均检测忙信号)
    LcdWriteCommand( 0x08, 1);            // 显示关闭
    LcdWriteCommand( 0x01, 1);            // 显示清屏
    LcdWriteCommand( 0x06, 1);            // 显示光标移动设置
    LcdWriteCommand( 0x0c, 1);            // 显示开及光标设置
    LcdWriteCommand( 0x02, 1);            // 显示开及光标设置
}

/*=======================================================
写控制字符子程序: E=1 RS=0 RW=0
=======================================================*/
void LcdWriteCommand( Uchar CMD,Uchar AttribC ) {
    if (AttribC) WaitForEnable();                // 检测忙信号?
    RS = 0;    RW = 0; _nop_();
    DataPort = CMD; _nop_();
    // 送控制字子程序
    Elcm = 1;_nop_();_nop_();Elcm = 0;           // 操作允许脉冲信号
}

/*=======================================================
当前位置写字符子程序: E =1 RS=1 RW=0
=======================================================*/
void LcdWriteData( char dataW ) {
    WaitForEnable();
    // 检测忙信号
    RS = 1; RW = 0; _nop_();
    DataPort = dataW; _nop_();
    Elcm = 1; _nop_(); _nop_(); Elcm = 0;        // 操作允许脉冲信号
}

/*=======================================================
正常读写操作之前必须检测LCD控制器状态:    CS=1 RS=0 RW=1
DB7:    0  LCD控制器空闲; 1  LCD控制器忙
========================================================*/
void WaitForEnable( void ) {
    DataPort = 0xff;
    RS =0; RW = 1; _nop_();    Elcm = 1; _nop_(); _nop_();
    while( DataPort & Busy );
    Elcm = 0;
}


// 短延时
void Delay5Ms(void)
{
    Uint i = 5552;
    while(i--);
}

//长延时
void Delay400Ms(void)
{
    Uchar i = 5;
    Uint j;
    while(i--)
    {
        j=7269;
        while(j--);
    };
}

void delay(unsigned int t) //延时
{       
  	unsigned int i, j; 
  	for(i=0;i<t;i++)
	{ 
  		for(j=0;j<10;j++)
		{;} 
    } 
} 

uint Adc(unsigned char n)
{
	unsigned char i;	
	uint result=0;

	ADC_CONTR = ADC_CONTR|0x80;
	delay(10);
	i = 0x01<<n;
        P1M0 = P1M0|i;
   	P1M1 = P1M1|i;
        delay(10); 
        ADC_CONTR = 0xE0|n;
        delay(10);
	ADC_DATA = 0;
	ADC_LOW2 = 0;
	ADC_CONTR = ADC_CONTR|0x08;
	delay(10);
        ADC_CONTR = ADC_CONTR&0xE7;
	result = ADC_DATA;
	result<<=2;
	result = result&0x03FC;
	result = result|(ADC_LOW2 & 0x03);
	return(result);
}

void cominit(void)
{
	SCON=0X50;
	TMOD=0X20;
	TH1=0xfd;
	TL1=0xfd;
	TR1=1;
	//ES=1;
	//EA=1;
}

uint Adc6(void)
{
	uint i,j,k;
	uint result=0;
	uint Tmin=0x3ff,Tmax=0;
	ulong T_tatol=0;
	uint temp1;
        uint comp;

	k=0;
        j=0;
        overflag=1;

        comp=3;// AdcMem; //值保存

        for(i=0;i<1000;i++)
	{
        temp1=Adc(2);// AdcMem; //值保存
		if(temp1<comp)
		{
			result=Adc(1);// AdcMem; //值保存
            temp1=Adc(2);// AdcMem; //值保存
			if(temp1>comp)
				continue;
		}
		else
        { 
            j++;
            if(j>900)
                return 0;
			continue;
        }
		k++;
		if(Tmin>result)
			Tmin=result;
		if(Tmax<result)
			Tmax=result;
		T_tatol=T_tatol+result;
	
		if(k==21)  
		{
			T_tatol=T_tatol-Tmin;
			T_tatol=T_tatol-Tmax;
			T_tatol>>=2;
            overflag=0;
			return((uint)T_tatol);
		}
	}
	return 0;
}

void send(uchar i)
{
	TI=0;
	SBUF=i;
	while(TI==0);
	TI=0;
}

void dispint(uint data1)
{
    uint tempAdc;
    tempAdc = data1%0x000A;
    lcd_data[0] = word_storeroom[tempAdc];
    data1 = data1/0x000A;
    tempAdc = data1%0x000A;
    lcd_data[1] = word_storeroom[tempAdc];
    data1 = data1/0x000A;
    tempAdc = data1%0x000A;
    lcd_data[2] = word_storeroom[tempAdc];

    //显示BCD码
    DispOneChar(4,1,lcd_data[2]);
    DispOneChar(5,1,'.');
    DispOneChar(6,1,lcd_data[1]);
    DispOneChar(7,1,lcd_data[0]);
}

void dispchar(uint data1,int x,int y)
{
    uchar tempAdc;
    tempAdc = data1%0x000A;
    lcd_data[0] = word_storeroom[tempAdc];
    data1 = data1/0x000A;
    tempAdc = data1%0x000A;
    lcd_data[1] = word_storeroom[tempAdc];
    data1 = data1/0x000A;
    tempAdc = data1%0x000A;
    lcd_data[2] = word_storeroom[tempAdc];
    data1 = data1/0x000A;
    tempAdc = data1%0x000A;
    lcd_data[3] = word_storeroom[tempAdc];

    //显示BCD码
    DispOneChar(x,y,lcd_data[3]);
    DispOneChar(x+1,y,lcd_data[2]);
    DispOneChar(x+2,y,lcd_data[1]);
    DispOneChar(x+3,y,lcd_data[0]);
}

/* 关闭 ISP,IAP 功能 */
void ISP_IAP_disable(void)
{
	ISP_CONTR=0;	/* 0111,1111 */
	ISP_CMD=0;
	ISP_TRIG=0;
//	EA=1;                	/* 开中断 */
}
/* 字节读 */
uchar byte_read(uint byte_addr)
{
	uchar tmp=0;

	ISP_CONTR	=	ENABLE_ISP;
	ISP_CMD		=	ISP_IAP_BYTE_READ;        /* 1111,1000 */
	ISP_ADDRH	=	(uchar)(byte_addr >> 8);
	ISP_ADDRL	=	(uchar)(byte_addr & 0x00ff);


	ISP_TRIG	=	0x46;
	ISP_TRIG	=	0xb9;
	_nop_();
	tmp=ISP_DATA;
	ISP_IAP_disable();
	return (tmp);
}
/* 扇区擦除 */
uchar sector_erase(uint sector_addr)
{
	ISP_CONTR       =       ENABLE_ISP;
	ISP_CMD  	=	ISP_IAP_SECTOR_ERASE;

	ISP_ADDRH	=	(uchar)(sector_addr >> 8);
	ISP_ADDRL	=	(uchar)(sector_addr & 0x00ff);

	ISP_TRIG	=	0x46;        /* 触发ISP_IAP命令 */
	ISP_TRIG	=	0xb9;        /* 触发ISP_IAP命令 */
	 _nop_();

	ISP_IAP_disable();
	return OK;
}
/* 字节编程 */
uchar byte_program(uint byte_addr, uchar original_data)
{
	ISP_CONTR       =       ENABLE_ISP;
	ISP_CMD		=	ISP_IAP_BYTE_PROGRAM;
	ISP_ADDRH	=	(uchar)(byte_addr >> 8);
	ISP_ADDRL	=	(uchar)(byte_addr & 0x00ff);
	ISP_DATA	=	original_data;

	ISP_TRIG	=	0x46;        /* 触发ISP_IAP命令 */
	ISP_TRIG	=	0xb9;        /* 触发ISP_IAP命令 */
	_nop_();

	ISP_IAP_disable();
	return	OK;
}
//中断函数，启动后每10MS进入一次中断
void T0_time(void) interrupt 1
{
    TH0=(65536-10000)/256;	//12M晶振10MS计时常数
    TL0=(65536-10000)%256;
    if(PWM)PWM=0; //输出脚取反
    else PWM=1;
}

main()
{ 
    uint tmp=0;
    uint temp=25;
    uint disptemp;
    uint rate=30;
    uint i,j;
    uint tmp_alarm;
    uint count;
    uint out=0;
    unsigned long limit;

    unsigned int TempH,TempL;
    unsigned int usertemp=20;      //开机设定20度
   
    char code *number4="T NOW:";
    char code *number5="T SET:";
    char code *number6="ON";
    char code *number7="OFF";

    j = 0xcf;
    P1M0 = P1M0&j;
    P1M1 = P1M1&j;
    P1M0 = P1M0&(0xf8);
    P1M1 = P1M1&(0xf8);
    P3M0 = P3M0&(0x00);
    P3M1 = P3M1&(0x80);

    LcdReset();
    Delay400Ms();
    cominit();	
 
    TMOD=0x01;	         //定时器0工作方式1
    TH0=(65536-10000)/256;	//12M晶振10MS计时常数
    TL0=(65536-10000)%256;
    EA=1;	//开总中断
    ET0=1;	//开定时器0中断
    TR0=1;	//启动定时器0

    for(i=0;i<8;i++)
    {
        DispOneChar(i,0,' ');
        DispOneChar(i,1,' ');
    }

    while(1) 
   {
   	if(!KEY_ADD)
	{
	    Delay5Ms();
	    Delay5Ms();
	    if(!KEY_ADD)
	    {
		while(!KEY_ADD)
		{
		    if(usertemp<60) usertemp++;
		    Delay400Ms();
		    Delay400Ms();
		    Delay400Ms();
	        }
	     }
	}

	if(!KEY_DEC)
	{
	    Delay5Ms();
	    Delay5Ms();
	    if(!KEY_DEC)
	    {
		while(!KEY_DEC)
		{
		    if(usertemp>20) usertemp--;
		    Delay400Ms();
		    Delay400Ms();
		    Delay400Ms();
		}
	    }
	}
                
        if(!KEY_ON_OFF)
	{
	    Delay5Ms();
	    Delay5Ms();
	    if(!KEY_ON_OFF)
	    {
	        while(!KEY_ON_OFF)
	        {
		    if(count==0) {count=1;}
                    else {count=0;}
                    Delay400Ms();
                    Delay400Ms();
                    Delay400Ms();
		}
	    }
	}
	tmp_alarm=Adc(7)*0.0698; //温度传感器改为6
	disptemp = temp/rate;	 //如果AD读入范围是0000~0500
	
	if(tmp_alarm<(usertemp-5)) ON_OFF=1;
	else if((tmp_alarm>=(usertemp-5))&&(tmp_alarm<usertemp)) ON_OFF=PWM;
        else if(tmp_alarm>=usertemp) ON_OFF=0;
	
        if(out==0) ON_OFF=ON_OFF;
	else if(out) ON_OFF=0;
        for(i=0;i<6;i++){
	    DispOneChar(i,0,*(number4+i));
	    DispOneChar(i,1,*(number5+i));
	}
	
	for(i=0;i<3;i++) DispOneChar(i+12,0,' ');
	if(count)
	{
	    for(i=0;i<2;i++) DispOneChar(i+12,0,*(number6+i));
	    if(tmp_alarm<(usertemp-5)){
		LED_Red	= 0;
		LED_Green = 0;
		LED_Yellow = 1;
	    }
            else if((tmp_alarm>=(usertemp-5))&&(tmp_alarm<usertemp)){
		LED_Red = 0;
		LED_Green = 1;
		LED_Yellow = 0;
	    }
	    else if(tmp_alarm>=usertemp){
		LED_Red = 1;
		LED_Green = 0;
		LED_Yellow = 0;
	    }
	}
	else if(count==0)
	{
	    for(i=0;i<3;i++) DispOneChar(i+12,0,*(number7+i));
	    LED_Red = 0;
	    LED_Green = 0;
	    LED_Yellow = 0;
	}
	dispchar(tmp_alarm,7,0);
	dispchar(usertemp,7,1);
    }
} //end_main
```
### 基于Min-Max搜索的黑白棋实验

```python
# -*- coding: utf-8 -*-
import random
import datetime
from board import Board
from game import Game 
from copy import deepcopy
import numpy as np

class RandomPlayer:
    """
    随机玩家, 随机返回一个合法落子位置
    """

    def __init__(self, color):
        """
        玩家初始化
        :param color: 下棋方，'X' - 黑棋，'O' - 白棋
        """
        self.color = color
        

    def random_choice(self, board):
        """
        从合法落子位置中随机选一个落子位置
        :param board: 棋盘
        :return: 随机合法落子位置, e.g. 'A1' 
        """
        # 用 list() 方法获取所有合法落子位置坐标列表
        action_list = list(board.get_legal_actions(self.color))

        # 如果 action_list 为空，则返回 None,否则从中选取一个随机元素，即合法的落子坐标
        if len(action_list) == 0:
            return None
        else:
            return random.choice(action_list)

    def get_move(self, board):
        """
        根据当前棋盘状态获取最佳落子位置
        :param board: 棋盘
        :return: action 最佳落子位置, e.g. 'A1'
        """
        if self.color == 'X':
            player_name = '黑棋'
        else:
            player_name = '白棋'
        print("请等一会，对方 {}-{} 正在思考中...".format(player_name, self.color))
        action = self.random_choice(board)
        return action


class HumanPlayer:
    """
    人类玩家
    """

    def __init__(self, color):
        """
        玩家初始化
        :param color: 下棋方，'X' - 黑棋，'O' - 白棋
        """
        self.color = color
    

    def get_move(self, board):
        """
        根据当前棋盘输入人类合法落子位置
        :param board: 棋盘
        :return: 人类下棋落子位置
        """
        # 如果 self.color 是黑棋 "X",则 player 是 "黑棋"，否则是 "白棋"
        if self.color == "X":
            player = "黑棋"
        else:
            player = "白棋"

        # 人类玩家输入落子位置，如果输入 'Q', 则返回 'Q'并结束比赛。
        # 如果人类玩家输入棋盘位置，e.g. 'A1'，
        # 首先判断输入是否正确，然后再判断是否符合黑白棋规则的落子位置
        while True:
            action = input(
                    "请'{}-{}'方输入一个合法的坐标(e.g. 'D3'，若不想进行，请务必输入'Q'结束游戏。): ".format(player, self.color))

            # 如果人类玩家输入 Q 则表示想结束比赛
            if action == "Q" or action == 'q':
                return "Q"
            else:
                row, col = action[1].upper(), action[0].upper()

                # 检查人类输入是否正确
                if row in '12345678' and col in 'ABCDEFGH':
                    # 检查人类输入是否为符合规则的可落子位置
                    if action in board.get_legal_actions(self.color):
                        return action
                else:
                    print("你的输入不合法，请重新输入!")


class AIPlayer:
    """
    AI 玩家
    """

    def __init__(self, color):
        """
        玩家初始化
        :param color: 下棋方，'X' - 黑棋，'O' - 白棋
        """

        self.color = color

    def game_over(self, board):
        """
        判断游戏是否结束
        :return: True/False 游戏结束/游戏没有结束
        """

        # 根据当前棋盘，判断棋局是否终止
        # 如果当前选手没有合法下棋的位子，则切换选手；如果另外一个选手也没有合法的下棋位置，则比赛停止。
        b_list = list(board.get_legal_actions('X'))
        w_list = list(board.get_legal_actions('O'))

        is_over = len(b_list) == 0 and len(w_list) == 0  # 返回值 True/False

        return is_over

    def get_move(self, board):
        """
        根据当前棋盘状态获取最佳落子位置
        :param board: 棋盘
        :return: action 最佳落子位置, e.g. 'A1'
        """
        if self.color == 'X':
            player_name = '黑棋'
        else:
            player_name = '白棋'
        print("请等一会，对方 {}-{} 正在思考中...".format(player_name, self.color))

        # -----------------请实现你的算法代码--------------------------------------
        
        # 定义棋盘落子估值
        boardpoint = [
        [90, -60, 10, 10, 10, 10, -60, 90], 
        [-60, -80, 5, 5, 5, 5, -80, -60], 
        [10, 5, 1, 1, 1, 1, 5, 10], 
        [10, 5, 1, 1, 1, 1, 5, 10],
        [10, 5, 1, 1, 1, 1, 5, 10], 
        [10, 5, 1, 1, 1, 1, 5, 10], 
        [-60, -80, 5, 5, 5, 5, -80, -60], 
        [90, -60, 10, 10, 10, 10, -60, 90]
        ]

        def minmax(board, action, player, op_player, depin, depinmax):
            
            # 递归出口
            if depin >= depinmax:
                return 0
            
            # 最大权值
            maxx = -10005
            # 保存当前棋盘
            board_ori = deepcopy(board._board)
            # 得到对方翻转棋子坐标
            # op_flips = board._can_fliped(action, player)
            # 判断action是不是字符串,如果是则转化为数字坐标
            if isinstance(action, str):
                action = board.board_num(action)
            x, y = action
            # 走棋,更新棋盘
            board._move(action, player)
            # 当前棋子权值
            Me = boardpoint[x][y] + 5 * board.count(player)

            MAXEXPECT = 0
            LINEEXPECT = 0

            # 预判对方是否可以走棋
            op_actions = list(board.get_legal_actions(op_player))
            if len(op_actions) != 0:
                for op_action in op_actions:
                    MAXEXPECT += 1
                    # 判断op_action是不是字符串,如果是则转化为数字坐标
                    if isinstance(op_action, str):
                        op_action = board.board_num(op_action)
                    x, y = op_action
                    # 判断对方是否有占角可能
                    if (x == 0 and y == 0) or (x == 0 and y == 7) or (x == 7 and y == 7) or (x == 7 and y == 0):
                        return -1800
                    if (x < 2 and y < 2) or (x < 2 and y > 5) or (x > 5 and y < 2) or (x > 5 and y > 5):
                        LINEEXPECT += 1
            
            # 如果对方走到坏点状态较多,剪枝
            if (LINEEXPECT * 10 > MAXEXPECT * 7):
                return 1400

            # 模拟对方走棋
            if len(op_actions) != 0:
                for op_action in op_actions:
                    # 判断op_action是不是字符串,如果是则转化为数字坐标
                    if isinstance(op_action, str):
                        op_action = board.board_num(op_action)
                    i, j = op_action
                    # 走棋,更新棋盘
                    board._move(op_action, op_player)
                    # 对手当前棋子权值
                    You = boardpoint[i][j] + 5 * board.count(op_player)
                    # 判断AI下一步能否走走棋
                    aimoves = list(board.get_legal_actions(player))
                    if len(aimoves) != 0:
                        for aimove in aimoves:
                            nowm = Me - You + minmax(board, aimove, player, op_player, depin + 1, depinmax)
                            if maxx < nowm:
                                maxx = nowm
                            else:
                                maxx = maxx
            
            # 恢复棋盘
            board._board = deepcopy(board_ori)
            return maxx
        
        # ------------------------------------------------------------------------

        board_o = deepcopy(board._board)
        maxx = -10005
        player = self.color
        op_player = "O" if player == "X" else "X"

        ai_actions = list(board.get_legal_actions(player))
        # print (len(ai_actions))
        action = random.choice(ai_actions)
        start_time = datetime.datetime.now()
        for ai_action in ai_actions:
            # 判断op_action是不是字符串,如果是则转化为数字坐标
            if isinstance(ai_action, str):
                ai_action = board.board_num(ai_action)
            x, y = ai_action
            ai_action = board.num_board(ai_action)
            if (x == 0 and y == 0) or (x == 0 and y == 7) or (x == 7 and y == 7) or (x == 7 and y == 0):
                action = ai_action
            # 递归搜索三层
            eva = minmax(board, ai_action, player, op_player, 0, 3)
            if eva >= maxx:
                maxx = eva
                action = ai_action
            # print (maxx)
            end_time = datetime.datetime.now()
            es_time = (end_time - start_time).seconds
            # print (es_time)
            if es_time > 25:
                break
        board._board = deepcopy(board_o)
        # ------------------------------------------------------------------------

        return action
```

### 基于区域二元线性回归模型的图像恢复
```python
def restore_image(noise_img, size=4):
    """
    使用 你最擅长的算法模型 进行图像恢复。
    :param noise_img: 一个受损的图像
    :param size: 输入区域半径，长宽是以 size*size 方形区域获取区域, 默认是 4
    :return: res_img 恢复后的图片，图像矩阵值 0-1 之间，数据类型为 np.array,
            数据类型对象 (dtype): np.double, 图像形状:(height,width,channel), 通道(channel) 顺序为RGB
    """
    # 恢复图片初始化，首先 copy 受损图片，然后预测噪声点的坐标后作为返回值。
    res_img = np.copy(noise_img)

    # 获取噪声图像
    noise_mask = get_noise_mask(noise_img)

    # -------------实现图像恢复代码答题区域----------------------------
    # 获得图像形状
    [height, width, channel] = noise_img.shape
    for row in range(height):
        for col in range(width):
            # 确定线性回归训练集区域 rowl-rowr
            if row - size < 0:
                rowl = 0
                rowr = rowl + 2 * size
            elif row + size >= height:
                rowr = height - 1
                rowl = rowr - 2 * size
            else:
                rowl = row - size
                rowr = row + size
           
            # 确定线性回归训练集区域 coll-colr
            if col - size < 0:
                coll = 0
                colr = coll + 2 * size
            elif col + size >= width:
                colr = width - 1
                coll = colr - 2 * size
            else:
                coll = col - size
                colr = col + size
            
            for k in range(channel):
                
                if noise_mask[row, col, k] != 0:
                    continue
              
                x_train = []
                y_train = []
                
                # 确定噪点位置并生成训练集
                for i in range(rowl, rowr):
                    for j in range(coll, colr):
                        if noise_mask[i, j, k] == 0.:
                            continue
                        if i == row and j == col:
                            continue
                        x_train.append([i, j])
                        y_train.append([noise_img[i, j, k]])
                if x_train == []:
                    continue
                
                # 对噪点进行预测
                Regression = Ridge()
                Regression.fit(x_train, y_train)
                if Regression.predict([[row, col]]) < 0:
                    res_img[row, col, k] = 0
                elif Regression.predict([[row, col]]) > 1:
                    res_img[row, col, k] = 1
                else:
                    res_img[row, col, k] = Regression.predict([[row, col]])
                    
    # ---------------------------------------------------------------
    return res_img

```
### I2C_Sender
```verilog
module i2c_sender(
    //input send_data,
    input clk_in,
    input reset,
    output i2c_scl,
    output i2c_sda
);

//wire [15:0] send_data;
//parameter  I2C_HDMI_ADDR = 8'h72;
parameter  ACK = 1'b1;

wire [15:0] I2C_CMD_PAIRS[0:39];
assign I2C_CMD_PAIRS[0] = 16'h0202;
assign I2C_CMD_PAIRS[1] = 16'h4110;
assign I2C_CMD_PAIRS[2] = 16'h9803;
assign I2C_CMD_PAIRS[3] = 16'h9AE0;
assign I2C_CMD_PAIRS[4] = 16'h9C30;
assign I2C_CMD_PAIRS[5] = 16'h9D32;
assign I2C_CMD_PAIRS[6] = 16'hA2A4;
assign I2C_CMD_PAIRS[7] = 16'hA3A4;
assign I2C_CMD_PAIRS[8] = 16'hE0D0;
assign I2C_CMD_PAIRS[9] = 16'h5512;
assign I2C_CMD_PAIRS[10] = 16'hF900;
assign I2C_CMD_PAIRS[11] = 16'h1501;
assign I2C_CMD_PAIRS[12] = 16'h4808;
assign I2C_CMD_PAIRS[13] = 16'h163C;
assign I2C_CMD_PAIRS[14] = 16'h1700;
assign I2C_CMD_PAIRS[15] = 16'hAF04;
assign I2C_CMD_PAIRS[16] = 16'h18E7;
assign I2C_CMD_PAIRS[17] = 16'h1934;
assign I2C_CMD_PAIRS[18] = 16'h1A04;
assign I2C_CMD_PAIRS[19] = 16'h1BAD;
assign I2C_CMD_PAIRS[20] = 16'h1C00;
assign I2C_CMD_PAIRS[21] = 16'h1D00;
assign I2C_CMD_PAIRS[22] = 16'h1E1C;
assign I2C_CMD_PAIRS[23] = 16'h1F1B;
assign I2C_CMD_PAIRS[24] = 16'h201D;
assign I2C_CMD_PAIRS[25] = 16'h21DC;
assign I2C_CMD_PAIRS[26] = 16'h2204;
assign I2C_CMD_PAIRS[27] = 16'h23AD;
assign I2C_CMD_PAIRS[28] = 16'h241F;
assign I2C_CMD_PAIRS[29] = 16'h2524;
assign I2C_CMD_PAIRS[30] = 16'h2311;
assign I2C_CMD_PAIRS[31] = 16'h2735;
assign I2C_CMD_PAIRS[32] = 16'h2800;
assign I2C_CMD_PAIRS[33] = 16'h2900;
assign I2C_CMD_PAIRS[34] = 16'h2A04;
assign I2C_CMD_PAIRS[35] = 16'h2BAD;
assign I2C_CMD_PAIRS[36] = 16'h2C08;
assign I2C_CMD_PAIRS[37] = 16'h2D7C;
assign I2C_CMD_PAIRS[38] = 16'h2E1B;
assign I2C_CMD_PAIRS[39] = 16'h2F77;
//assign I2C_CMD_PAIRS[40] = send_data;

/* YOUR CODE*/

// divde clk from 50MHz to 100KHz
reg [15:0]   counter=0;
reg          CLK_100K_A=0;
reg          CLK_100K_B=0;

wire CLK_100K_SDA;  // debug
wire CLK_100K_SCL;  // debug

always @(posedge clk_in or posedge reset)
begin
    if (reset)  begin counter = 0; CLK_100K_A = 0; CLK_100K_B = 0; end
    else begin
        counter = counter + 1;
        if (counter == 175) CLK_100K_A = ~CLK_100K_A;
        if (counter >= 250) begin CLK_100K_B = ~CLK_100K_B; counter = 0; end
    end
end
   
assign   CLK_100K_SDA = CLK_100K_A | CLK_100K_B;
assign   CLK_100K_SCL = CLK_100K_A & CLK_100K_B;

reg [32:0]   SDA_BUFFER, SCL_BUFFER;
reg [15:0]   DA_NUM = 0;
reg          DA_EN = 0; 
reg [7:0]    count = 0;
reg [7:0]    count_1 = 0;
reg [7:0]    count_2 = 0;

always @(posedge CLK_100K_SCL) 
begin
    if (reset) begin DA_EN = 0; count = 0; count_1 = 0; count_2 = 0;end
    else begin
        if (DA_EN)
            SCL_BUFFER = {2'b10,27'b0,2'b11};
        else 
            SCL_BUFFER = {SCL_BUFFER[29:0],1'b1};
        if(count < 32 && DA_EN == 0)
        begin
            count = count + 1;
        end
        if(count == 32 && DA_EN == 0)
        begin
            DA_EN = 1;
        end
        if(count_2 < 3 && DA_EN == 1)
        begin
            count_2 = count_2 + 1;
        end
        if(count_2 == 3 && DA_EN == 1)
        begin
            count = 0;
            DA_EN = 0;
            count_2 = 0;
            if(count_1 < 40)
                count_1 = count_1 + 1;
            else
                count_1 = 40;
        end

    end
end

reg [7:0]  I2C_HDMI_ADDR;
always @(posedge CLK_100K_SDA) 
begin
    if (reset);
    else begin
        DA_NUM = I2C_CMD_PAIRS[count_1];
        if (count_1 == 0) I2C_HDMI_ADDR = 8'hE8;
        else I2C_HDMI_ADDR = 8'h72;
        if (DA_EN) begin
            SDA_BUFFER = {2'b10,I2C_HDMI_ADDR,ACK,DA_NUM[15:8],ACK,DA_NUM[7:0],ACK,2'b01};
        end
        else 
            SDA_BUFFER = {SDA_BUFFER[29:0],1'b1};
    end
end

assign i2c_scl = (count_1 < 40)? (CLK_100K_SCL || SCL_BUFFER[30]) : 1'b1;
assign i2c_sda = (count_1 < 40)? SDA_BUFFER[30] : 1'b1;

//assign i2c_scl = CLK_100K_SCL || SCL_BUFFER[30];
//assign i2c_sda = SDA_BUFFER[30];

endmodule
```
