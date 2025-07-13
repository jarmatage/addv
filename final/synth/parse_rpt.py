from pathlib import Path

import matplotlib.pyplot as plt
import polars as pl
import seaborn as sns


def get_power(path: Path) -> tuple[float, float, float]:
    """Extract the power values from a report file."""
    with path.open("r") as f:
        for line in reversed(list(f)):
            if line.startswith("Total"):
                vals = line.split()
                internal = float(vals[1])
                switching = float(vals[3])
                leakage = float(vals[5]) / 1e6
                return internal, switching, leakage
    return -1e3, -1e3, -1e3

def get_slack(path: Path) -> float:
    """Extract the WNS from a timing report file."""
    with path.open("r") as f:
        for line in reversed(list(f)):
            if line.startswith("  slack"):
                return float(line.split()[-1])
    return -1e3

def get_cell_area(path: Path) -> float:
    """Extract the cell area from a report file."""
    with path.open("r") as f:
        for line in reversed(list(f)):
            if line.startswith("Total cell area"):
                return float(line.split()[-1])
    return -1e3

def get_df(path: Path) -> pl.DataFrame:
    """Parse each report directory to make a table of PPA values."""
    data = []
    for dir in [d for d in path.iterdir() if d.is_dir()]:
        wperiod, rperiod = [float(p) for p in dir.name.split("_")]
        internal, switching, leakage = get_power(dir / "power.rpt")

        data.append({
            "wperiod": wperiod,
            "rperiod": rperiod,
            "slack": get_slack(dir / "timing.rpt"),
            "cell_area": get_cell_area(dir / "area.rpt"),
            "total_power": internal + switching + leakage,
            "dynamic_power": switching + internal,
            "internal_power": internal,
            "switching_power": switching,
            "leakage_power": leakage,
        })
    return pl.DataFrame(data).sort(["wperiod", "rperiod"])

def plot_df(df: pl.DataFrame) -> None:
    """Plot the PPA values from the DataFrame."""
    pdf = df.to_pandas()
    
    heatmap_data = pdf.pivot(index="wperiod", columns="rperiod", values="total_power")
    ax = sns.heatmap(heatmap_data, annot=False, cmap="viridis", xticklabels=3, yticklabels=3)
    ax.set_xlabel("Read Clock Period (ns)")
    ax.set_ylabel("Write Clock Period (ns)")
    if (cbar := ax.collections[0].colorbar):
        cbar.set_label("Total Power (mW)")
    plt.title("Total Power vs Read/Write Clock Periods")
    plt.savefig("total_power.png")
    plt.clf()

    heatmap_data = pdf.pivot(index="wperiod", columns="rperiod", values="slack")
    ax = sns.heatmap(heatmap_data, annot=False, cmap="viridis", xticklabels=3, yticklabels=3)
    ax.set_xlabel("Read Clock Period (ns)")
    ax.set_ylabel("Write Clock Period (ns)")
    if (cbar := ax.collections[0].colorbar):
        cbar.set_label("WNS (ns)")
    plt.title("WNS vs Read/Write Clock Periods")
    plt.savefig("wns.png")
    plt.clf()

    heatmap_data = pdf.pivot(index="wperiod", columns="rperiod", values="cell_area")
    ax = sns.heatmap(heatmap_data, annot=False, cmap="viridis", xticklabels=3, yticklabels=3)
    ax.set_xlabel("Read Clock Period (ns)")
    ax.set_ylabel("Write Clock Period (ns)")
    if (cbar := ax.collections[0].colorbar):
        cbar.set_label("Cell Area (um^2)")
    plt.title("Cell Area vs Read/Write Clock Periods")
    plt.savefig("cell_area.png")
    plt.clf()


if __name__ == "__main__":
    ppa = get_df(Path("rpt"))
    ppa.write_csv("ppa.csv")
    plot_df(ppa)
