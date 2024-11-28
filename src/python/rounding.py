import pandas as pd
import numpy as np
from tqdm import tqdm

def round_near_integers_with_progress(input_file, output_file, threshold=0.1):
    # Read the CSV into a DataFrame
    df = pd.read_csv(input_file)
    
    # Define a rounding function
    def round_values(value):
        if np.isclose(value, 0, atol=threshold):
            return 0
        elif np.isclose(value, 1, atol=threshold):
            return 1
        elif np.isclose(value, -1, atol=threshold):
            return -1
        else:
            return value
    
    # Apply tqdm to add a progress bar when rounding columns
    tqdm.pandas(desc="Rounding values")
    
    # Apply rounding to all columns except 'ID' and 'room_ID'
    columns_to_round = df.select_dtypes(include=[np.number]).columns.drop(['ID', 'room_ID'])
    for col in tqdm(columns_to_round, desc="Processing columns"):
        df[col] = df[col].progress_apply(round_values)
    
    # Save the cleaned DataFrame to a new CSV file
    df.to_csv(output_file, index=False)

# File paths
input_file = 'src\\python\\full_data.csv'  # Replace with your input file name
output_file = 'src\\python\\cleaned_data_with_progress.csv'

# Run the function
round_near_integers_with_progress(input_file, output_file)
