create or replace function public.enqueue_subscription_order_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_name text;
  v_amount_label text;
  v_status_label text;
  v_user_title text;
  v_user_body text;
  v_admin_title text;
  v_admin_body text;
begin
  select coalesce(nullif(trim(full_name), ''), 'User ' || left(new.user_id::text, 8))
    into v_user_name
  from public.profiles
  where id = new.user_id;

  if v_user_name is null then
    v_user_name := 'User ' || left(new.user_id::text, 8);
  end if;

  v_amount_label := trim(to_char(coalesce(new.amount, 0), 'FM999G999G999G999')) || ' VND';

  if tg_op = 'UPDATE' and coalesce(new.status, '') = coalesce(old.status, '') then
    return new;
  end if;

  if coalesce(new.status, 'pending') = 'pending' then
    v_status_label := 'Dang cho thanh toan';
    v_user_title := 'Da tao ma QR thanh toan';
    v_user_body := format('Don %s - %s (ma #%s) da san sang.', new.plan_name, v_amount_label, new.order_code);
    v_admin_title := 'Giao dich moi cho thanh toan';
    v_admin_body := format('%s vua tao ma QR cho goi %s - %s (ma #%s).', v_user_name, new.plan_name, v_amount_label, new.order_code);
  elsif new.status = 'paid' then
    v_status_label := 'Thanh toan thanh cong';
    v_user_title := 'Thanh toan thanh cong';
    v_user_body := format('Ban da thanh toan thanh cong don %s (%s).', new.plan_name, v_amount_label);
    v_admin_title := 'Giao dich thanh cong';
    v_admin_body := format('%s vua thanh toan thanh cong goi %s (%s), ma #%s.', v_user_name, new.plan_name, v_amount_label, new.order_code);
  elsif new.status = 'cancelled' then
    v_status_label := 'Da huy thanh toan';
    v_user_title := 'Da huy thanh toan';
    v_user_body := format('Giao dich #%s (%s) da duoc huy.', new.order_code, new.plan_name);
    v_admin_title := 'Giao dich da huy';
    v_admin_body := format('%s da huy giao dich goi %s (%s), ma #%s.', v_user_name, new.plan_name, v_amount_label, new.order_code);
  else
    v_status_label := 'Thanh toan that bai';
    v_user_title := 'Thanh toan that bai';
    v_user_body := format('Giao dich #%s (%s) that bai. Vui long thu lai.', new.order_code, new.plan_name);
    v_admin_title := 'Giao dich that bai';
    v_admin_body := format('%s co giao dich that bai cho goi %s (%s), ma #%s.', v_user_name, new.plan_name, v_amount_label, new.order_code);
  end if;

  insert into public.notifications (recipient_user_id, type, title, body, metadata)
  values (
    new.user_id,
    'payment_' || coalesce(new.status, 'pending'),
    v_user_title,
    v_user_body,
    jsonb_build_object(
      'orderCode', new.order_code,
      'planId', new.plan_id,
      'planName', new.plan_name,
      'amount', new.amount,
      'status', coalesce(new.status, 'pending'),
      'statusLabel', v_status_label
    )
  );

  insert into public.notifications (recipient_user_id, type, title, body, metadata)
  select
    p.id,
    'admin_payment_' || coalesce(new.status, 'pending'),
    v_admin_title,
    v_admin_body,
    jsonb_build_object(
      'userId', new.user_id,
      'userName', v_user_name,
      'orderCode', new.order_code,
      'planId', new.plan_id,
      'planName', new.plan_name,
      'amount', new.amount,
      'status', coalesce(new.status, 'pending'),
      'statusLabel', v_status_label
    )
  from public.profiles p
  where p.role = 'admin';

  return new;
end;
$$;

drop trigger if exists trg_subscription_orders_notifications on public.subscription_orders;

create trigger trg_subscription_orders_notifications
after insert or update of status on public.subscription_orders
for each row
execute function public.enqueue_subscription_order_notifications();