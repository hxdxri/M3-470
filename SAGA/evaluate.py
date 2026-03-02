import json
import csv

# Load oracle
oracle_pairs = {}
with open("bigclonebench_subset/oracle/oracle_pairs.jsonl") as f:
    for line in f:
        pair = json.loads(line)
        oracle_pairs[(pair["id1"], pair["id2"])] = pair["label"]

# Load MeasureIndex to map measure index -> snippet_id
measure_to_snippet = {}
with open("result/MeasureIndex.csv") as f:
    for row in csv.reader(f):
        measure_idx = int(row[0])
        filepath = row[1]
        # Extract snippet ID from filename e.g. Snippet_1363.java
        filename = filepath.replace("\\", "/").split("/")[-1]
        snippet_id = int(filename.replace("Snippet_", "").replace(".java", ""))
        measure_to_snippet[measure_idx] = snippet_id

# Load SAGA results
detected_pairs = []
with open("result/type123_method_pair_result.csv") as f:
    for row in csv.reader(f):
        m1, m2 = int(row[0]), int(row[1])
        s1 = measure_to_snippet.get(m1)
        s2 = measure_to_snippet.get(m2)
        if s1 and s2:
            detected_pairs.append((min(s1,s2), max(s1,s2)))

# Compute precision and recall
true_positives = 0
for s1, s2 in detected_pairs:
    label = oracle_pairs.get((s1, s2)) or oracle_pairs.get((s2, s1))
    if label:
        true_positives += 1

total_detected = len(detected_pairs)
total_positive_oracle = sum(1 for v in oracle_pairs.values() if v)

precision = true_positives / total_detected if total_detected > 0 else 0
recall = true_positives / total_positive_oracle if total_positive_oracle > 0 else 0

# Pairs where both snippets are in oracle but not as a pair
oracle_snippet_ids = set()
for pair in oracle_pairs:
    oracle_snippet_ids.add(pair[0])
    oracle_snippet_ids.add(pair[1])

in_oracle_coverage = sum(1 for s1,s2 in detected_pairs 
                         if s1 in oracle_snippet_ids and s2 in oracle_snippet_ids)
print(f"Detected pairs where both snippets appear in oracle: {in_oracle_coverage}")
print(f"Detected pairs outside oracle coverage: {total_detected - in_oracle_coverage}")

print(f"Total detected pairs: {total_detected}")
print(f"True positives: {true_positives}")
print(f"Total positive pairs in oracle: {total_positive_oracle}")
print(f"Precision: {precision:.4f}")
print(f"Recall: {recall:.4f}")