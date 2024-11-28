import pandas as pd
import numpy as np
from tqdm import tqdm

# Assuming `data` is the DataFrame provided
data['dist_to_nearest'] = np.inf  # Initialize with infinity for all rows

# Function to calculate Euclidean distance between two bounding boxes
def compute_distance(row1, row2, dimensions=['x', 'y', 'z']):
    deltas = []
    for dim in dimensions:
        delta = (row1[f'centroid_{dim}'] - row2[f'centroid_{dim}']) ** 2
        deltas.append(delta)
    return np.sqrt(sum(deltas))

# Iterate over each unique room_ID
for room_id in tqdm(data['room_ID'].unique(), desc="Processing room_IDs"):
    room_data = data[data['room_ID'] == room_id]
    
    # Iterate over each bounding box in the room
    for i, row in room_data.iterrows():
        min_distance = np.inf
        for j, other_row in room_data.iterrows():
            if i != j:  # Skip the current box itself
                dist = compute_distance(row, other_row, dimensions=['x', 'y', 'z'])
                min_distance = min(min_distance, dist)
        
        # Update the distance for this row in the main DataFrame
        data.at[i, 'dist_to_nearest'] = min_distance