import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinding Visualization',
      home: PathfindingGrid(),
    );
  }
}

class PathfindingGrid extends StatefulWidget {
  @override
  _PathfindingGridState createState() => _PathfindingGridState();
}

class _PathfindingGridState extends State<PathfindingGrid> with TickerProviderStateMixin {
  static const int gridSize = 50;
  static const double blockProbability = 0.3;
  List<List<Cell>> grid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => Cell(i, j)));
  Random random = Random();
  Cell? startCell;
  Cell? goalCell;
  List<Cell> path = [];
  bool selectingStart = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    generateBlocks();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void generateBlocks() {
    for (var row in grid) {
      for (var cell in row) {
        if (random.nextDouble() < blockProbability) {
          cell.isBlock = true;
        }
      }
    }
  }

  void findPath(String algorithm) async {
    if (startCell == null || goalCell == null) return;

    switch (algorithm) {
      case 'A*':
        aStarPathfinding();
        break;
      case 'BFS':
        bfsPathfinding();
        break;
      case 'DFS':
        dfsPathfinding();
        break;
      case 'UCS':
        ucsPathfinding();
        break;
      case 'DLS':
        dlsPathfinding(50); // depth limit 50 olarak ayarlandı
        break;
      case 'ID-DFS':
        iddfsPathfinding();
        break;
      case 'Greedy BeFS':
        greedyBeFSPathfinding();
        break;
      case 'Weighted A*':
        weightedAStarPathfinding();
        break;
    }
  }

  void aStarPathfinding() {
    PriorityQueue<Cell> openSet = HeapPriorityQueue((a, b) => a.fCost.compareTo(b.fCost));
    Set<Cell> closedSet = {};
    openSet.add(startCell!);

    while (openSet.isNotEmpty) {
      Cell current = openSet.removeFirst();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      closedSet.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor) || neighbor.isBlock) continue;

        int tentativeGCost = current.gCost + 1;
        if (tentativeGCost < neighbor.gCost || !openSet.contains(neighbor)) {
          neighbor.gCost = tentativeGCost;
          neighbor.hCost = getDistance(neighbor, goalCell!);
          neighbor.parent = current;

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }
  }

  void bfsPathfinding() {
    Queue<Cell> queue = Queue<Cell>();
    Set<Cell> visited = {};

    queue.add(startCell!);
    visited.add(startCell!);

    while (queue.isNotEmpty) {
      Cell current = queue.removeFirst();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      for (var neighbor in getNeighbors(current)) {
        if (!visited.contains(neighbor) && !neighbor.isBlock) {
          neighbor.parent = current;
          queue.add(neighbor);
          visited.add(neighbor);
        }
      }
    }
  }

  void dfsPathfinding() {
    Stack<Cell> stack = Stack<Cell>();
    Set<Cell> visited = {};

    stack.push(startCell!);
    visited.add(startCell!);

    while (stack.isNotEmpty) {
      Cell current = stack.pop();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      for (var neighbor in getNeighbors(current)) {
        if (!visited.contains(neighbor) && !neighbor.isBlock) {
          neighbor.parent = current;
          stack.push(neighbor);
          visited.add(neighbor);
        }
      }
    }
  }

  void ucsPathfinding() {
    PriorityQueue<Cell> openSet = HeapPriorityQueue((a, b) => a.gCost.compareTo(b.gCost));
    Set<Cell> closedSet = {};
    openSet.add(startCell!);

    while (openSet.isNotEmpty) {
      Cell current = openSet.removeFirst();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      closedSet.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor) || neighbor.isBlock) continue;

        int tentativeGCost = current.gCost + 1;
        if (tentativeGCost < neighbor.gCost || !openSet.contains(neighbor)) {
          neighbor.gCost = tentativeGCost;
          neighbor.parent = current;

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }
  }

  void dlsPathfinding(int limit) {
    Set<Cell> visited = {};
    bool found = dls(startCell!, limit, visited);

    if (found) {
      retracePath(goalCell!);
    }
  }

  bool dls(Cell current, int limit, Set<Cell> visited) {
    if (current == goalCell) return true;
    if (limit <= 0) return false;

    visited.add(current);

    for (var neighbor in getNeighbors(current)) {
      if (!visited.contains(neighbor) && !neighbor.isBlock) {
        neighbor.parent = current;
        bool found = dls(neighbor, limit - 1, visited);
        if (found) return true;
      }
    }

    return false;
  }

  void iddfsPathfinding() {
    for (int limit = 0; limit < gridSize * gridSize; limit++) {
      Set<Cell> visited = {};
      bool found = dls(startCell!, limit, visited);

      if (found) {
        retracePath(goalCell!);
        return;
      }
    }
  }

  void greedyBeFSPathfinding() {
    PriorityQueue<Cell> openSet = HeapPriorityQueue((a, b) => a.hCost.compareTo(b.hCost));
    Set<Cell> closedSet = {};
    startCell!.hCost = getDistance(startCell!, goalCell!);
    openSet.add(startCell!);

    while (openSet.isNotEmpty) {
      Cell current = openSet.removeFirst();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      closedSet.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor) || neighbor.isBlock) continue;

        neighbor.hCost = getDistance(neighbor, goalCell!);
        neighbor.parent = current;

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        }
      }
    }
  }

  void weightedAStarPathfinding() {
    double weight = 2.0;
    PriorityQueue<Cell> openSet = HeapPriorityQueue((a, b) => a.fCost.compareTo(b.fCost));
    Set<Cell> closedSet = {};
    openSet.add(startCell!);

    while (openSet.isNotEmpty) {
      Cell current = openSet.removeFirst();

      if (current == goalCell) {
        retracePath(current);
        return;
      }

      closedSet.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor) || neighbor.isBlock) continue;

        int tentativeGCost = current.gCost + 1;
        if (tentativeGCost < neighbor.gCost || !openSet.contains(neighbor)) {
          neighbor.gCost = tentativeGCost;
          neighbor.hCost = (getDistance(neighbor, goalCell!) * weight).toInt();
          neighbor.parent = current;

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }
  }

  List<Cell> getNeighbors(Cell cell) {
    List<Cell> neighbors = [];

    if (cell.x > 0) neighbors.add(grid[cell.x - 1][cell.y]);
    if (cell.x < gridSize - 1) neighbors.add(grid[cell.x + 1][cell.y]);
    if (cell.y > 0) neighbors.add(grid[cell.x][cell.y - 1]);
    if (cell.y < gridSize - 1) neighbors.add(grid[cell.x][cell.y + 1]);

    return neighbors;
  }

  int getDistance(Cell a, Cell b) {
    int distX = (a.x - b.x).abs();
    int distY = (a.y - b.y).abs();
    return distX + distY;
  }

  void retracePath(Cell endCell) {
    List<Cell> path = [];
    Cell current = endCell;

    while (current != startCell) {
      path.add(current);
      current = current.parent!;
    }
    path.add(startCell!);
    path = path.reversed.toList();
    animatePath(path);
  }

  void animatePath(List<Cell> path) {
    for (int i = 0; i < path.length; i++) {
      Timer(Duration(milliseconds: i * 100), () {
        setState(() {
          this.path.add(path[i]);
        });
      });
    }
  }

  void handleCellTap(Cell cell) {
    setState(() {
      if (selectingStart) {
        startCell = cell;
      } else {
        goalCell = cell;
      }
      selectingStart = !selectingStart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pathfinding Visualization'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                ),
                itemBuilder: (context, index) {
                  int x = index % gridSize;
                  int y = index ~/ gridSize;
                  Cell cell = grid[x][y];

                  Color color;
                  if (cell == startCell) {
                    color = Colors.green;
                  } else if (cell == goalCell) {
                    color = Colors.red;
                  } else if (cell.isBlock) {
                    color = Colors.black;
                  } else if (path.contains(cell)) {
                    color = Colors.blue;
                  } else {
                    color = Colors.white;
                  }

                  return GestureDetector(
                    onTap: () => handleCellTap(cell),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          margin: EdgeInsets.all(1),
                          color: color,
                        );
                      },
                    ),
                  );
                },
                itemCount: gridSize * gridSize,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => findPath('A*'),
                    child: Text('A* Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('BFS'),
                    child: Text('BFS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('DFS'),
                    child: Text('DFS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('UCS'),
                    child: Text('UCS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('DLS'),
                    child: Text('DLS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('ID-DFS'),
                    child: Text('ID-DFS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('Greedy BeFS'),
                    child: Text('Greedy BeFS Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: () => findPath('Weighted A*'),
                    child: Text('Weighted A* Başlat'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Cell {
  final int x, y;
  bool isBlock = false;
  int gCost = 0;
  int hCost = 0;
  Cell? parent;

  Cell(this.x, this.y);

  int get fCost => gCost + hCost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Cell &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Stack<T> {
  final _list = <T>[];

  void push(T value) => _list.add(value);

  T pop() => _list.removeLast();

  bool get isNotEmpty => _list.isNotEmpty;
}
