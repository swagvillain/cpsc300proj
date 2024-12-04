

import pickle
import numpy as np
import os.path
import pandas as pd

model_file_path = r"src/python/COMFE_model.pkl"
with open(model_file_path, 'rb') as f:
    model = pickle.load(f)
input_file_path  = r"src/python/query.txt"
array = []

if not os.path.isfile(input_file_path):
    print(f'File "{input_file_path}" does not exist.')
else:
    with open(input_file_path) as f:
        content = f.readlines()

    for line in content:
        array.append(line)

    # centroids: x, y, z coordinates of centre of object
    # coeffiecents: multipliers denoting width/length/height of obj 
    # room_ID: random int 0-3440
    # dist_to_nearest: distance between this and nearest boundingbox
    feature_names = ['centroid_x','centroid_y','centroid_z','coeffs_x','coeffs_y','coeffs_z','room_ID','dist_to_nearest']

    input_row = np.array([array])
    input_row_df = pd.DataFrame([array], columns=feature_names)

    prediction = model.predict(input_row_df)

    print(prediction)

    # Output


