## Signify面试
### 基于Min-Max搜索的黑白棋实验
```python
# -*- coding: utf-8 -*-
import random
import datetime
from board import Board
from game import Game 
from copy import deepcopy
import numpy as np

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
### I2C Burst Write
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
### ICCAD Problem1
```bash
#!/bin/bash

while :
do

#将目录放在while循环内,可以实现每次输入前显示menu要求,在程序开始和结尾处添加-线可以方便程序执行时区分指令
echo "---------------------------------------------------------------------------------------
Options:
1, List all files in current directory and sub-directories in long format
2, List only hidden files in current directory and sub-directories in long format
3, Read in a name, report whether it is a file, a user, a device, a command, or nobody
4, Read in a file name, show it in hexadecimal format if you have executable permission
5, Let '/usr/bin/ftp' automatically download "demo_inout.c" from our course ftp site
q, Quit
"

read -p "pls input an option: " option
  case "$option" in
    1)
        ls -Ral                  #-R表示递归,可以显示子目录
        ;;
    2)
        find -type f -iname ".*" #找到所有以.开头的文件/隐藏文件
        ;;
    3)
        read -p "pls input a name: " name
        if [ -f "$name" ]; then         #-f表示如果输入名称表示的是一个文件,返回真
          echo "$name is a file!"
        elif [ -e /dev/$name ]; then    #linux系统中device存放在/dev/下,-e表示当device文件存在时,返回真
          echo "$name is a device!"     
        elif [ -e /bin/$name ]; then    #linux系统中command存放在/bin/以及/usr/bin下
          echo "$name is a command!"
        elif [ -e /usr/bin/$name ]; then
          echo "$name is a command!"
        elif [ `cat /etc/passwd | grep $name` ]; then  #如果user不存在,则grep $name为假,否则为真,类似比对查找
          echo "$name is a user!"
        else
          echo "$name is nobody!"
        fi
        ;;
    4)
        read -p "pls input a filename: " filename
        filelocate=`locate $filename | grep "/$filename"`  #利用locate指令定位文件,但是也会存在其他名称相似的文件,所以添加grep指令
        location=${filelocate%/*}     #%/*表示删除字符串右边第一个/及其右边所有字符
        if [ "$filelocate" ]; then
          echo "$filename is an existing file!"
          file_permission=`cd $location && ls -l | grep " $filename"`  #利用cd指令到达文件所在目录,再通过ls -l以及grep指令查找文件详细信息
          echo "$file_permission"
          permission=`cd $location && ls -l | grep "$filename" | cut -c 4-4`  #在这里为了化简,只是查询了文件创建者的执行权限,由于本机用户有限,不能另外登录其他用户,不好判断代码的准确性,以后会再改进
          if [ "${file_permission:4:1}"="-" ]; then
            echo "$filename doesn't have executable permission!"
          else
            xxd $filelocate
          fi
        else
          echo "$filename is not an existing file!"
        fi
        ;;
    5)
        read -p "pls input a command: " command
        if [ "$command"="/usr/bin/ftp" ]; then     #Shell中通常将EOF与 << 结合使用，表示后续的输入作为子命令或子Shell的输入，直到遇到EOF为止，再返回到主调Shell
          ftp -v -n 10.212.43.214 << EOF      
            user anonymous password
            cd Course/ICCAD/demo
            binary
            prompt
            get demo_inout.c
            bye
EOF
          echo "get demo_inout.c done"
        fi
        ;;
    q)
        read -p "press [y] to qiut: " quit_option
        if [ "$quit_option" = "y" ]; then
          exit
        fi
        ;;
    *)
        read -p "pls input an option: " option1   #当第一次输入不是要求指令时,将第一次输入保存为第二次执行时的输入,并读取第二次输入命令,执行选项
        case "$option1" in
          3)
            if [ -f "$option" ]; then
              echo "$option is a file!"
            elif [ -e /dev/$option ]; then
              echo "$option is a device!"
            elif [ -e /bin/$option ]; then
              echo "$option is a command!"
            elif [ -e /usr/bin/$name ]; then
              echo "$option is a command!"
            elif [ `cat /etc/passwd | grep $option` ]; then
              echo "$option is a user!"
            else
              echo "$option is nobody!"
            fi
            ;;
          4)
            filelocate=`locate $option | grep "/$option"`
            location=${filelocate%/*}
            if [ "$filelocate" ]; then
              echo "$option is an existing file!"
              file_permission=`cd $location && ls -l | grep " $option"`
              echo "$file_permission"
              permission=`cd $location && ls -l | grep "$option" | cut -c 4-4`
              if [ "${file_permission:4:1}"="-" ]; then
                echo "$option doesn't have executable permission!"
              else
                xxd $filelocate
              fi
            else
              echo "$option is not an existing file!"
            fi
        esac
  esac
done
```
