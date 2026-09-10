install:
	pip install -r requirements.txt

test:
	pytest -q project/tests

# The extraction frontier, regenerated from cached responses. No GPU, no network.
frontier:
	cd project && python scripts/benchmark_table.py

# Claims -> resolved, dated edges with validity intervals.
graph:
	cd project && python scripts/build_graph.py

# The pre-registered signal test. Runs once, when the corpus is complete.
signal:
	cd project && python scripts/run_signal_test.py

# Writes the redistributable point-in-time layer to project/dist/.
dataset:
	cd project && python scripts/export_dataset.py

.PHONY: install test frontier graph signal dataset
