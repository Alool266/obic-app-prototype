// Made by Dr Ali
// Who may see a colleague in the company directory. Phone and email stay separate.

export const DIRECTORY_VISIBILITIES = ['company', 'branch', 'department'] as const;

export type DirectoryVisibility = (typeof DIRECTORY_VISIBILITIES)[number];

export function isDirectoryVisibility(value: string): value is DirectoryVisibility {
  return (DIRECTORY_VISIBILITIES as readonly string[]).includes(value);
}

export type DirectoryViewer = {
  id: string;
  role: 'Employee' | 'SuperAdmin';
  branchLabel: string | null;
  departmentId: string | null;
};

export type DirectorySubject = {
  id: string;
  branchLabel: string | null;
  departmentId: string | null;
  /** Null when the person is not in a department. */
  departmentVisibility: DirectoryVisibility | null;
};

/** Same branch label, ignoring case and surrounding spaces. Blank labels never match. */
export function sameDirectoryBranch(
  left: string | null,
  right: string | null,
): boolean {
  const a = (left ?? '').trim().toLowerCase();
  const b = (right ?? '').trim().toLowerCase();
  if (!a || !b) return false;
  return a === b;
}

/**
 * SuperAdmin sees every colleague.
 * A department set to `company` is visible to all staff.
 * `branch` is visible inside that branch.
 * `department` is visible only to members of that department.
 * Someone with no department is visible only inside their branch.
 */
export function canSeeDirectoryMember(
  viewer: DirectoryViewer,
  subject: DirectorySubject,
): boolean {
  if (viewer.role === 'SuperAdmin') return true;
  if (viewer.id === subject.id) return true;

  const visibility = subject.departmentVisibility;
  if (!subject.departmentId || visibility == null) {
    return sameDirectoryBranch(viewer.branchLabel, subject.branchLabel);
  }

  switch (visibility) {
    case 'company':
      return true;
    case 'branch':
      return sameDirectoryBranch(viewer.branchLabel, subject.branchLabel);
    case 'department':
      return (
        viewer.departmentId != null &&
        viewer.departmentId === subject.departmentId
      );
    default: {
      const unreachable: never = visibility;
      return unreachable;
    }
  }
}

/** Phone and email: SuperAdmin, and a person looking at their own card. */
export function directoryShowsContact(
  viewer: DirectoryViewer,
  subjectId: string,
): boolean {
  if (viewer.role === 'SuperAdmin') return true;
  return viewer.id === subjectId;
}
