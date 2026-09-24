// Made by Dr Ali
// Saved delivery / contact addresses on the user profile (JSONB).

export interface UserAddress {
  id: string;
  label: string;
  line1: string;
  line2?: string;
  city: string;
  district?: string;
  notes?: string;
  isDefault?: boolean;
}
