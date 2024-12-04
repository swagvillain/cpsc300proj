

import pickle
import numpy as np
import os.path
import pandas as pd

model_file_path = r"src/python/COMFE_model.pkl"
with open(model_file_path, 'rb') as f:
    model = pickle.load(f)
input_file_path  = r"src/godot/cpsc300_projectv1/query.txt"
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

    # Get the prediction from the model
    prediction = model.predict(input_row_df)

    output_string = np.array2string(prediction)
    output_string = output_string[1:2]
    print(output_string)

    # Output
    output_file_path = "src/godot/cpsc300_projectv1/consult_output.txt"

    output = open(output_file_path, 'w')

    # 1 for accepted, 0 for unaccepted
    output.write(output_string)


