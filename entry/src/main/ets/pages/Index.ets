import { promptAction } from '@kit.ArkUI';

const BOARD_SIZE = 4;
const EMPTY_TAG = 0;
const SHUFFLE_MOVES = 200;

interface Position {
  row: number;
  col: number;
}

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
struct HuarongGame {
  @State board: number[][] = getInitialBoard();
  @State gameWon: boolean = false;
  @State moveCount: number = 0;
  @State startTime: number = 0;
  @State timer: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.startNewGame();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  findEmptyPosition(board: number[][]): Position {
    for (let i = 0; i < BOARD_SIZE; i++) {
      for (let j = 0; j < BOARD_SIZE; j++) {
        if (board[i][j] === EMPTY_TAG) return { row: i, col: j };
      }
    }
    return { row: -1, col: -1 };
  }

  getMovableNeighbors(row: number, col: number, board: number[][]): Position[] {
    const neighbors: Position[] = [];
    const directions = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (const dir of directions) {
      const newRow = row + dir[0];
      const newCol = col + dir[1];
      if (newRow >= 0 && newRow < BOARD_SIZE && newCol >= 0 && newCol < BOARD_SIZE) {
        if (board[newRow][newCol] !== EMPTY_TAG) {
          neighbors.push({ row: newRow, col: newCol });
        }
      }
    }
    return neighbors;
  }

  startNewGame(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
    let newBoard = getInitialBoard();
    let emptyPos = this.findEmptyPosition(newBoard);
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

  tryMove(row: number, col: number): void {
    if (this.gameWon) return;
    const emptyPos = this.findEmptyPosition(this.board);
    const isNeighbor = Math.abs(emptyPos.row - row) + Math.abs(emptyPos.col - col) === 1;
    if (!isNeighbor) return;

    let newBoard = copyBoard(this.board);
    newBoard[emptyPos.row][emptyPos.col] = newBoard[row][col];
    newBoard[row][col] = EMPTY_TAG;
    this.board = newBoard;
    this.moveCount++;

    if (this.checkWin(this.board)) {
      this.gameWon = true;
      if (this.timerId !== -1) clearInterval(this.timerId);
      promptAction.showDialog({
        title: '🎉 胜利！',
        message: `恭喜通关！\n移动步数：${this.moveCount}\n用时：${this.timer}秒`,
        buttons: [{ text: '再玩一局', color: '#007DFF' }]
      }).then(() => this.startNewGame()).catch(() => this.startNewGame());
    }
  }

  checkWin(board: number[][]): boolean {
    let expected = 1;
    for (let i = 0; i < BOARD_SIZE; i++) {
      for (let j = 0; j < BOARD_SIZE; j++) {
        if (i === BOARD_SIZE - 1 && j === BOARD_SIZE - 1) return board[i][j] === EMPTY_TAG;
        if (board[i][j] !== expected++) return false;
      }
    }
    return false;
  }

  @Builder
  GridItem(row: number, col: number): void {
    Text(this.board[row][col] === EMPTY_TAG ? '' : this.board[row][col].toString())
      .width(80)
      .height(80)
      .backgroundColor(this.board[row][col] === EMPTY_TAG ? '#F0F0F0' : '#007DFF')
      .fontColor(this.board[row][col] !== EMPTY_TAG ? '#FFFFFF' : '#FF9800')
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
      .borderRadius(12)
      .margin(4)
      .onClick(() => {
        if (!this.gameWon && this.board[row][col] !== EMPTY_TAG) {
          this.tryMove(row, col);
        }
      })
  }

  @Builder
  GridRow(rowIndex: number): void {
    Row() {
      this.GridItem(rowIndex, 0);
      this.GridItem(rowIndex, 1);
      this.GridItem(rowIndex, 2);
      this.GridItem(rowIndex, 3);
    }
    .justifyContent(FlexAlign.Center)
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
          .onClick(() => this.startNewGame())
      }
      .width('100%')
      .padding(12)
      .justifyContent(FlexAlign.SpaceEvenly)

      Column() {
        this.GridRow(0);
        this.GridRow(1);
        this.GridRow(2);
        this.GridRow(3);
      }
      .width('90%')
      .backgroundColor('#FAFAFA')
      .borderRadius(20)
      .padding(10)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}