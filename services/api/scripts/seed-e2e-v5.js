#!/usr/bin/env node
// Made by Dr Ali — seed a physical E2E story for Progress Update 5 screenshots.
// New customer → service request → Marketing Manager chat → service group.

const API = process.env.API_BASE_URL || 'http://127.0.0.1:3001';

async function json(method, path, body, token) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function login(email, password) {
  const data = await json('POST', '/v1/auth/login', { email, password });
  return data.accessToken;
}

async function main() {
  const stamp = Date.now().toString().slice(-6);
  const customerEmail = `demo.customer.${stamp}@obic.local`;
  const customerPass = 'DemoCust2026!';

  console.log('API', API);
  await json('GET', '/v1/health');

  // 1) New customer registers
  const reg = await json('POST', '/v1/auth/register', {
    email: customerEmail,
    password: customerPass,
    name: `Demo Customer ${stamp}`,
    phone: `+8613800${stamp}`,
  });
  const customerToken = reg.accessToken;
  const customerId = reg.user?.id || reg.id;
  console.log('customer', customerEmail, customerId);

  // 2) Pick a real service UUID and create an order (Yiwu)
  const services = await json('GET', '/v1/services');
  const list = Array.isArray(services) ? services : services.items || [];
  if (!list.length) throw new Error('No services in catalog');
  const service = list[0];
  const order = await json(
    'POST',
    '/v1/orders',
    {
      serviceId: service.id,
      preferredBranch: 'Yiwu',
      notes: `Progress Update 5 demo — need help with ${service.nameEn || service.slug || 'service'}`,
    },
    customerToken,
  );
  console.log('order', order.id, order.status);

  // 3) Marketing Manager (Yiwu) opens DM and chats
  const mktEmail = 'temp.yiwu.marketing@obic.local';
  const mktPass = 'TempObic2026!Yiwu-Mkt';
  const mktToken = await login(mktEmail, mktPass);
  const mktMe = await json('GET', '/v1/users/me', null, mktToken);
  console.log('marketer', mktMe.name, mktMe.id);

  const dm = await json(
    'POST',
    '/v1/chat/threads',
    { kind: 'direct', peerUserId: customerId || reg.user.id },
    mktToken,
  );
  const dmId = dm.id;
  await json(
    'POST',
    `/v1/chat/threads/${dmId}/messages`,
    {
      body: 'مرحباً — أنا مدير التسويق في فرع ييوو. استلمت طلبك وسأساعدك.',
    },
    mktToken,
  );
  await json(
    'POST',
    `/v1/chat/threads/${dmId}/messages`,
    {
      body: 'شكراً لكم. أحتاج إجراءات ترخيص الأعمال في ييوو.',
    },
    customerToken,
  );
  console.log('dm', dmId);

  // 4) Create service group: customer + data entry + marketer
  const deToken = await login(
    'temp.yiwu.dataentry@obic.local',
    'TempObic2026!Yiwu-Data',
  );
  const deMe = await json('GET', '/v1/users/me', null, deToken);

  const group = await json(
    'POST',
    '/v1/chat/threads',
    {
      kind: 'group',
      title: `ييوو · فنادق · ${stamp}`,
      memberUserIds: [customerId || reg.user.id, deMe.id],
    },
    mktToken,
  );
  const groupId = group.id;
  await json(
    'POST',
    `/v1/chat/threads/${groupId}/messages`,
    {
      body: 'تم فتح المجموعة — انضم إدخال البيانات. سنجمع المستندات هنا.',
    },
    mktToken,
  );
  await json(
    'POST',
    `/v1/chat/threads/${groupId}/messages`,
    {
      body: 'تم الاستلام. يرجى رفع جواز السفر وأوراق الشركة عند الجاهزية.',
    },
    deToken,
  );
  await json(
    'POST',
    `/v1/chat/threads/${groupId}/messages`,
    {
      body: 'شكراً لكم — سجهّز الملفات اليوم.',
    },
    customerToken,
  );
  console.log('group', groupId, group.title);

  // Write capture hints
  const fs = require('fs');
  const out = {
    customerEmail,
    customerPass,
    customerId: customerId || reg.user.id,
    orderId: order.id,
    dmId,
    groupId,
    groupTitle: group.title,
    marketerEmail: mktEmail,
    marketerPass: mktPass,
    dataEntryEmail: 'temp.yiwu.dataentry@obic.local',
  };
  fs.writeFileSync('/tmp/obic-e2e-v5.json', JSON.stringify(out, null, 2));
  console.log('WROTE /tmp/obic-e2e-v5.json');
  console.log(JSON.stringify(out, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
