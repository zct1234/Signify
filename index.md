## Signify面试

You can use the [editor on GitHub](https://github.com/zct1234/Signify/edit/gh-pages/index.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```python
# -*- coding: utf-8 -*-
import random
import datetime
from board import Board
from game import Game 
from copy import deepcopy

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
                    "请'{}-{}'方输入一个合法的坐标(e.g. 'D3'，若不想进行，请务必输入'Q'结束游戏。): ".format(player,
                                                                                 self.color))

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

import random
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

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/zct1234/Signify/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://docs.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.
