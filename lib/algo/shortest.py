import heapq

def dijkstra(graph, start):
    distances = {node: float('infinity') for node in graph}
    distances[start] = 0

    priority_queue = [(0, start)]

    while priority_queue:
        current_distance, current_node = heapq.heappop(priority_queue)
        if current_distance > distances[current_node]:
            continue
        for neighbor, weight in graph[current_node].items():
            distance = current_distance + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(priority_queue, (distance, neighbor))

    return distances

#test
if __name__ == "__main__":
    graph = {
        'Vet 1': {'B': 1, 'C': 4},
        'Vet 2': {'A': 1, 'C': 2, 'D': 6},
        'Vet 3': {'A': 4, 'B': 2, 'D': 3},
        'Vet $': {'B': 6, 'C': 3}
    }

    start_node = 'A'
    shortest_paths = dijkstra(graph, start_node)

    print(f"Shortest paths from {start_node}:")
    for node, distance in shortest_paths.items():
        print(f"Node {node}: Distance {distance}")
