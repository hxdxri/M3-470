import json
import argparse
import os

# Paths (adapt as needed)
ORACLE_PATH = os.path.join(os.path.dirname(__file__), '../benchmarks/bcb_subset/oracle_pairs.jsonl')
RESULTS_PATH = os.path.join(os.path.dirname(__file__), '../SourcererCC/results/bcb_subset_results.pairs')
METRICS_PATH = os.path.join(os.path.dirname(__file__), '../SourcererCC/results/sourcerercc_metrics.json')
INDEX_MAP_PATH = os.path.join(os.path.dirname(__file__), '../benchmarks/bcb_subset/index_to_snippet_id.json')


def load_oracle(path):
    oracle_pairs = {}
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            pair = json.loads(line)
            key = tuple(sorted([pair["id1"], pair["id2"]]))
            oracle_pairs[key] = pair["label"]
    return oracle_pairs


def load_index_map(path):
    with open(path, 'r', encoding='utf-8') as f:
        return {int(k): v for k, v in json.load(f).items()}


def load_detected_pairs(path, index_map):
    pairs = set()
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split(',')
            if len(parts) >= 4:
                idx1 = int(parts[1])
                idx2 = int(parts[3])
                id1 = index_map.get(idx1)
                id2 = index_map.get(idx2)
                if id1 is not None and id2 is not None:
                    pairs.add(tuple(sorted([id1, id2])))
    return pairs


def compute_metrics(oracle_pairs, detected_pairs):
    tp = 0
    fp = 0
    fn = 0
    for pair in detected_pairs:
        if pair in oracle_pairs and oracle_pairs[pair]:
            tp += 1
        else:
            fp += 1
    for pair, label in oracle_pairs.items():
        if label and pair not in detected_pairs:
            fn += 1
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    return {
        "true_positives": tp,
        "false_positives": fp,
        "false_negatives": fn,
        "precision": precision,
        "recall": recall
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate SourcererCC output against BCB oracle subset.")
    parser.add_argument('--oracle', type=str, default=ORACLE_PATH, help='Path to oracle_pairs.jsonl')
    parser.add_argument('--results', type=str, default=RESULTS_PATH, help='Path to bcb_subset_results.pairs')
    parser.add_argument('--metrics', type=str, default=METRICS_PATH, help='Path to output metrics JSON')
    parser.add_argument('--index_map', type=str, default=INDEX_MAP_PATH, help='Path to index_to_snippet_id.json')
    args = parser.parse_args()

    oracle_pairs = load_oracle(args.oracle)
    index_map = load_index_map(args.index_map)
    detected_pairs = load_detected_pairs(args.results, index_map)
    metrics = compute_metrics(oracle_pairs, detected_pairs)

    with open(args.metrics, 'w', encoding='utf-8') as f:
        json.dump(metrics, f, indent=2)
    print(f"Metrics written to {args.metrics}")
    print(json.dumps(metrics, indent=2))

if __name__ == "__main__":
    main()
