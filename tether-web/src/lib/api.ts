const API_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, '') ?? 'http://localhost:3001';

export async function apiFetch<T>(
  path: string,
  options: RequestInit & { token?: string } = {},
): Promise<T> {
  const { token, headers, ...rest } = options;
  const response = await fetch(`${API_URL}${path}`, {
    ...rest,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    cache: 'no-store',
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${response.status} ${path}: ${body}`);
  }

  return response.json() as Promise<T>;
}

export type GymStats = {
  memberCount: number;
  workoutsThisWeek: number;
  pendingCount: number;
  flaggedCount: number;
};

export type GymSettings = {
  id: string;
  name: string;
  logoUrl: string | null;
  primaryColor: string | null;
  timezone: string;
  contactEmail: string | null;
  subscriptionTier: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

export type GymStaffMember = {
  id: string;
  gymId: string;
  email: string;
  role: 'admin' | 'coach' | string;
  authProviderId: string | null;
  createdAt: string;
  updatedAt: string;
};

export type GymMember = {
  id: string;
  email: string | null;
  phone: string | null;
  displayName: string | null;
  subscriptionTier: string;
  createdAt: string;
  lastWorkoutAt: string | null;
  workoutsLast30Days: number;
};

export type DashboardRange = 'today' | 'week' | 'month';

export type GymDashboard = {
  range: DashboardRange;
  timezone: string;
  generatedAt: string;
  kpis: {
    members: { value: number; newCurrent: number; newPrevious: number };
    activeNow: number;
    workouts: { current: number; previous: number };
    pending: number;
    flagged: number;
  };
  activity: {
    granularity: 'hour' | 'day';
    currentLabel: string;
    previousLabel: string;
    points: Array<{ label: string; current: number | null; previous: number }>;
  };
  tiers: Array<{ name: string; value: number }>;
  busyHours: {
    days: string[];
    hours: number[];
    grid: number[][];
    max: number;
    windowDays: number;
  };
  weeklyGoal: { current: number; target: number; daysLeft: number };
  topPrograms: Array<{
    id: string;
    name: string;
    source: string;
    coachName: string | null;
    sessions: number;
  }>;
  coaches: {
    total: number;
    trainingNow: number;
    list: Array<{
      staffId: string;
      name: string;
      email: string;
      hasAppAccount: boolean;
      isTrainingNow: boolean;
      programCount: number;
    }>;
  };
  pendingRoster: Array<{
    id: string;
    name: string;
    contact: string | null;
    createdAt: string;
  }>;
};

export type StaffMemberProfile = {
  memberId: string;
  displayName: string;
  email: string | null;
  phone: string | null;
  subscriptionTier: string;
  avatarUrl: string | null;
  staffRole: string | null;
  gym: {
    id: string;
    name: string;
  };
  isOwnProfile: boolean;
  stats: {
    workoutCount: number;
    totalSets: number;
    totalVolume: number;
    streakDays: number;
  };
  posts: Array<{
    id: string;
    gymId: string;
    authorId: string;
    authorName: string;
    content: string;
    imageUrl: string | null;
    imagePath: string | null;
    achievementType: string | null;
    workoutSessionId: string | null;
    workoutSummary: {
      durationSeconds: number;
      totalSets: number;
      exerciseCount: number;
      volumeKg: number;
      exerciseNames: string[];
    } | null;
    authorIsStaff: boolean;
    authorStaffRole: string | null;
    isOwnPost: boolean;
    coachCertification: {
      coachName: string;
      certifiedAt: string;
    } | null;
    likeCount: number;
    commentCount: number;
    isLiked: boolean;
    isFlagged: boolean;
    createdAt: string;
  }>;
  postsHasMore: boolean;
  sharedRoutines: Array<{
    id: string;
    name: string;
    difficulty: string | null;
    updatedAt: string;
    exercises: Array<{
      id: string;
      exercise: {
        id: string;
        name: string;
      };
    }>;
  }>;
};

export type PendingRosterEntry = {
  id: string;
  gymId: string;
  email: string | null;
  phone: string | null;
  memberName: string | null;
  externalMemberId: string | null;
  status: string;
  createdAt: string;
};

export type RosterCsvRowResult = {
  row: number;
  status: 'ok' | 'error';
  message?: string;
};

export type StaffNotice = {
  id: string;
  gymId: string;
  authorUserId: string | null;
  authorStaffId: string | null;
  title: string;
  body: string;
  tag: 'ANNOUNCEMENT' | 'CLASS_UPDATE' | 'REMINDER' | 'EVENT' | string;
  isPinned: boolean;
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  authorUser?: {
    id: string;
    displayName: string | null;
  } | null;
  authorStaff?: {
    id: string;
    email: string;
    role: string;
  } | null;
};

export type ModerationPost = {
  id: string;
  gymId: string;
  userId: string;
  content: string | null;
  imageUrl: string | null;
  achievementType: string | null;
  isFlagged: boolean;
  isDeleted: boolean;
  createdAt: string;
  authorName: string;
  authorRole: string | null;
  likeCount: number;
  commentCount: number;
  flagCount: number;
  coachCertification: {
    coachName: string;
    certifiedAt: string;
  } | null;
};
