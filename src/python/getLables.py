import os
import json
import pandas as pd
from tqdm import tqdm  # Import tqdm for progress bar

# Base directories for annotations and bounding boxes
base_dir_annotation_3d = "C:\\Users\\swagvillain\\Downloads\\Structured3D_annotation_3d\\Structured3D"
base_dir_bbox = "C:\\Users\\swagvillain\\Downloads\\Structured3D_bbox\\Structured3D"

# Placeholder for the updated bounding box data
bbox_data_with_labels = []

# List all scene directories for progress tracking
scene_dirs = [scene_dir for scene_dir in os.listdir(base_dir_bbox) if os.path.isdir(os.path.join(base_dir_bbox, scene_dir))]

# Use tqdm to track progress
for scene_dir in tqdm(scene_dirs, desc="Processing scenes"):
    bbox_scene_path = os.path.join(base_dir_bbox, scene_dir)
    annotation_scene_path = os.path.join(base_dir_annotation_3d, scene_dir)

    if not os.path.isdir(bbox_scene_path) or not os.path.isdir(annotation_scene_path):
        continue

    # Paths to the annotation files
    bbox_file = os.path.join(bbox_scene_path, "bbox_3d.json")
    annotation_file = os.path.join(annotation_scene_path, "annotation_3d.json")

    if not os.path.exists(bbox_file) or not os.path.exists(annotation_file):
        continue

    # Load the data
    with open(bbox_file, "r") as bf:
        bbox_data = json.load(bf)
    with open(annotation_file, "r") as af:
        annotation_data = json.load(af)

    # Create a lookup table for semantics
    semantics = {entry["ID"]: entry["type"] for entry in annotation_data["semantics"]}

    # Assign semantic labels to bounding boxes
    for bbox in bbox_data:
        bbox_id = bbox["ID"]
        # Find the semantic label
        label = semantics.get(bbox_id, "unknown")  # Default to 'unknown' if not found
        bbox["semantic_label"] = label
        bbox["scene_id"] = scene_dir  # Add scene ID for tracking
        bbox_data_with_labels.append(bbox)

# Convert to DataFrame
df = pd.DataFrame(bbox_data_with_labels)

# Save the updated table
output_file = "C:\\Users\\swagvillain\\Downloads\\bounding_boxes_with_labels.csv"
df.to_csv(output_file, index=False)

print(f"Updated bounding box table saved to {output_file}")
