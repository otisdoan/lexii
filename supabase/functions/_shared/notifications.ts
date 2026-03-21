// @ts-nocheck

export async function notifyUser(
  adminClient: any,
  recipientUserId: string,
  payload: {
    type: string;
    title: string;
    body: string;
    metadata?: Record<string, unknown>;
  },
): Promise<void> {
  if (!recipientUserId) return;

  const { error } = await adminClient.from('notifications').insert({
    recipient_user_id: recipientUserId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    metadata: payload.metadata ?? {},
  });

  if (error) {
    console.error('notifyUser failed:', error.message);
  }
}

export async function notifyAdmins(
  adminClient: any,
  payload: {
    type: string;
    title: string;
    body: string;
    metadata?: Record<string, unknown>;
  },
): Promise<void> {
  const { data: adminProfiles, error: adminError } = await adminClient
    .from('profiles')
    .select('id')
    .eq('role', 'admin');

  if (adminError) {
    console.error('notifyAdmins load admins failed:', adminError.message);
    return;
  }

  const adminIds = (adminProfiles || []).map((row: { id: string }) => row.id).filter(Boolean);
  if (!adminIds.length) return;

  const rows = adminIds.map((adminId: string) => ({
    recipient_user_id: adminId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    metadata: payload.metadata ?? {},
  }));

  const { error: insertError } = await adminClient.from('notifications').insert(rows);
  if (insertError) {
    console.error('notifyAdmins insert failed:', insertError.message);
  }
}

export function statusToVi(status: string): string {
  switch ((status || '').toLowerCase()) {
    case 'pending':
      return 'Đang chờ thanh toán';
    case 'paid':
      return 'Thanh toán thành công';
    case 'cancelled':
      return 'Đã hủy thanh toán';
    case 'failed':
      return 'Thanh toán thất bại';
    default:
      return 'Cập nhật giao dịch';
  }
}

export function formatVnd(amount: number): string {
  try {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(amount);
  } catch (_) {
    return `${amount} VND`;
  }
}
