// Made by Dr Ali

import {
  canSeeDirectoryMember,
  directoryShowsContact,
  sameDirectoryBranch,
  type DirectorySubject,
  type DirectoryViewer,
} from './directory-visibility';

const employee: DirectoryViewer = {
  id: 'emp',
  role: 'Employee',
  branchLabel: 'Yiwu',
  departmentId: 'visas',
};

function person(overrides: Partial<DirectorySubject> = {}): DirectorySubject {
  return {
    id: 'other',
    branchLabel: 'Yiwu',
    departmentId: 'visas',
    departmentVisibility: 'branch',
    ...overrides,
  };
}

describe('company directory visibility', () => {
  it('matches branch labels without case or extra spaces', () => {
    expect(sameDirectoryBranch(' Yiwu ', 'yiwu')).toBe(true);
    expect(sameDirectoryBranch('', 'Yiwu')).toBe(false);
    expect(sameDirectoryBranch('Yiwu', 'Guangzhou')).toBe(false);
  });

  it('lets SuperAdmin see every colleague and their contact fields', () => {
    const admin: DirectoryViewer = {
      id: 'sa',
      role: 'SuperAdmin',
      branchLabel: null,
      departmentId: null,
    };
    expect(
      canSeeDirectoryMember(
        admin,
        person({ branchLabel: 'Hainan', departmentVisibility: 'department' }),
      ),
    ).toBe(true);
    expect(directoryShowsContact(admin, 'other')).toBe(true);
  });

  it('shows a company-wide department to every employee', () => {
    expect(
      canSeeDirectoryMember(
        employee,
        person({
          branchLabel: 'Shanghai',
          departmentId: 'lead',
          departmentVisibility: 'company',
        }),
      ),
    ).toBe(true);
  });

  it('keeps a branch department inside that branch', () => {
    expect(canSeeDirectoryMember(employee, person())).toBe(true);
    expect(
      canSeeDirectoryMember(employee, person({ branchLabel: 'Foshan' })),
    ).toBe(false);
  });

  it('keeps a department-only list inside that department', () => {
    expect(
      canSeeDirectoryMember(
        employee,
        person({ departmentVisibility: 'department' }),
      ),
    ).toBe(true);
    expect(
      canSeeDirectoryMember(
        employee,
        person({
          departmentId: 'shipping',
          departmentVisibility: 'department',
        }),
      ),
    ).toBe(false);
  });

  it('shows an unassigned colleague only inside the same branch, without phone or email', () => {
    expect(
      canSeeDirectoryMember(
        employee,
        person({ departmentId: null, departmentVisibility: null }),
      ),
    ).toBe(true);
    expect(
      canSeeDirectoryMember(
        employee,
        person({
          branchLabel: 'Yemen',
          departmentId: null,
          departmentVisibility: null,
        }),
      ),
    ).toBe(false);
    expect(directoryShowsContact(employee, 'other')).toBe(false);
    expect(directoryShowsContact(employee, 'emp')).toBe(true);
  });
});
