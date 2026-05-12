import { promptAction } from '@kit.ArkUI';

const BOARD_SIZE = 4;
const EMPTY_TAG = 0;
const SHUFFLE_MOVES = 200;

// 1. 显式声明接口，解决对象字面量类型问题
interface Position {
  row: number;
  col: number;
}

// 工具函数：生成初始完成状态棋盘
function getInitialBoard(): number[][] {
  let board: number[][] = [];
  let counter = 1;
  for (let i = 0; i < BOARD_SIZE; i++) {
    board[i] = [];
    for (let j = 0; j < BOARD_SIZE; j++) {
      board[i][j] = (i === BOARD_SIZE - 1 && j === BOARD_SIZE - 1) ? EMPTY_TAG : counter++;
    }
  }
  return board;
}

function copyBoard(source: number[][]): number[][] {
  return source.map(row => [...row]);
}

@Entry
@Component
struct HuarongGame {   // 改名避免拼写警告
  @State board: number[][] = getInitialBoard();
  @State gameWon: boolean = false;
  @State moveCount: number = 0;
  @State startTime: number = 0;
  @State timer: number = 0;
  private timerId: number = -1;

  aboutToAppear() {
    this.startNewGame();
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  // 返回类型使用接口 Position
  findEmptyPosition(board: number[][]): Position {
    for (let i = 0; i < BOARD_SIZE; i++) {
      for (let j = 0; j < BOARD_SIZE; j++) {
        if (board[i][j] === EMPTY_TAG) {
          return { row: i, col: j };
        }
      }
    }
    return { row: -1, col: -1 };
  }

  // 返回类型为 Position 数组
  getMovableNeighbors(row: number, col: number, board: number[][]): Position[] {
    const neighbors: Position[] = [];
    const directions = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    // 3. 不使用解构赋值，改为直接索引
    for (const dir of directions) {
      const dx = dir[0];
      const dy = dir[1];
      const newRow = row + dx;
      const newCol = col + dy;
      if (newRow >= 0 && newRow < BOARD_SIZE && newCol >= 0 && newCol < BOARD_SIZE) {
        if (board[newRow][newCol] !== EMPTY_TAG) {
          neighbors.push({ row: newRow, col: newCol });
        }
      }
    }
    return neighbors;
  }

  startNewGame() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
    let newBoard = getInitialBoard();
    let emptyPos = this.findEmptyPosition(newBoard);

    // 逆向合法移动打乱
    for (let i = 0; i < SHUFFLE_MOVES; i++) {
      const neighbors = this.getMovableNeighbors(emptyPos.row, emptyPos.col, newBoard);
      if (neighbors.length > 0) {
        const randomNeighbor = neighbors[Math.floor(Math.random() * neighbors.length)];
        newBoard[emptyPos.row][emptyPos.col] = newBoard[randomNeighbor.row][randomNeighbor.col];
        newBoard[randomNeighbor.row][randomNeighbor.col] = EMPTY_TAG;
        emptyPos = randomNeighbor;
      }
    }

    this.board = newBoard;
    this.gameWon = false;
    this.moveCount = 0;
    this.startTime = Date.now();
    this.timerId = setInterval(() => {
      this.timer = Math.floor((Date.now() - this.startTime) / 1000);
    }, 1000);
  }

  tryMove(row: number, col: number) {
    if (this.gameWon) return;

    const emptyPos = this.findEmptyPosition(this.board);
    const isNeighbor = Math.abs(emptyPos.row - row) + Math.abs(emptyPos.col - col) === 1;

    if (isNeighbor) {
      let newBoard = copyBoard(this.board);
      newBoard[emptyPos.row][emptyPos.col] = newBoard[row][col];
      newBoard[row][col] = EMPTY_TAG;
      this.board = newBoard;
      this.moveCount++;

      if (this.checkWin(this.board)) {
        this.gameWon = true;
        if (this.timerId !== -1) {
          clearInterval(this.timerId);
        }
        // 4. 处理可能的异常：添加 .catch()
        promptAction.showDialog({
          title: '🎉 胜利！',
          message: `恭喜通关！\n移动步数：${this.moveCount}\n用时：${this.timer}秒`,
          buttons: [{ text: '再玩一局', color: '#007DFF' }]
        }).then(() => {
          this.startNewGame();
        }).catch((err: Error) => {
          console.error(`Dialog error: ${err.message}`);
          this.startNewGame(); // 出错也重启游戏
        });
      }
    }
  }

  checkWin(board: number[][]): boolean {
    let expected = 1;
    for (let i = 0; i < BOARD_SIZE; i++) {
      for (let j = 0; j < BOARD_SIZE; j++) {
        if (i === BOARD_SIZE - 1 && j === BOARD_SIZE - 1) {
          return board[i][j] === EMPTY_TAG;
        }
        if (board[i][j] !== expected++) {
          return false;
        }
      }
    }
    return false;
  }

  build() {
    Column() {
      Row() {
        Text(`步数: ${this.moveCount}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(`用时: ${this.timer} s`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button('重置')
          .fontSize(20)
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.startNewGame();
          })
      }
      .width('100%')
      .padding(12)
      .justifyContent(FlexAlign.SpaceEvenly)

      Grid() {
        ForEach(this.board, (row: number[], rowIndex: number) => {
          ForEach(row, (cell: number, colIndex: number) => {
            GridItem() {
              Text(cell !== EMPTY_TAG ? cell.toString() : '')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(cell !== EMPTY_TAG ? '#FFFFFF' : '#FF9800')
                .backgroundColor(cell !== EMPTY_TAG ? '#007DFF' : '#F0F0F0')
                .width('100%')
                .height('100%')
                .borderRadius(12)
                .textAlign(TextAlign.Center)
            }
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 6, color: '#CCCCCC', offsetX: 2, offsetY: 2 })
            .onClick(() => {
              if (!this.gameWon && cell !== EMPTY_TAG) {
                this.tryMove(rowIndex, colIndex);
              }
            })
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .height('70%')
      .width('90%')
      .padding(10)
      .backgroundColor('#FAFAFA')
      .borderRadius(20)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}