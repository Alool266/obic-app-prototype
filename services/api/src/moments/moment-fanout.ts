// Made by Dr Ali
// Moments fan-out recipient selection (staff vs friends).

export function momentNotifyCandidateMode(isStaff: boolean): 'all' | 'friends' {
  return isStaff ? 'all' : 'friends';
}
