interface Coord {
  r: number;
  c: number;
}

interface Cluster {
  cells: Coord[];
  size: number;
}

interface WinningCluster {
  reward: number;
  size: number;
}

interface Ticket {
  goldenStars: Coord[];
  clusters: Cluster[]; // we compute these
  winningCluster: WinningCluster | null;
  win: boolean;
}

interface PrizeTier {
  minCluster: number;
  reward: number;
}

interface State {
  isOpen: boolean;
  scratched: boolean;
  goldenStars: Coord[];
  serial: string;
	tiers: PrizeTier[]
}

interface NUIPayload {
  serial: string;
  scratched: boolean;
  goldenStars: Coord[];
  tiers: PrizeTier[];
}
