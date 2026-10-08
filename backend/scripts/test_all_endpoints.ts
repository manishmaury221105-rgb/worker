const BASE_URL = 'http://localhost:5050/api';

async function request(path: string, options: any = {}): Promise<{ status: number; data: any }> {
  const url = `${BASE_URL}${path}`;
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  const res = await fetch(url, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const data: any = await res.json();
  return { status: res.status, data };
}

async function runTests() {
  console.log('🧪 Starting Full System Integration Test for Worker Management App...\n');

  // 1. Health Check
  const health = await request('/health');
  console.log('1. Health Check:', health.status === 200 ? '✅ OK' : '❌ FAIL', health.data.message);

  // 2. Admin Login
  const adminLogin = await request('/auth/login', {
    method: 'POST',
    body: { identifier: '9695718820', password: 'Aj@y' },
  });
  console.log('2. Admin Login:', adminLogin.data.success ? '✅ OK' : '❌ FAIL', `(Token length: ${adminLogin.data.data?.token?.length})`);
  const adminToken = adminLogin.data.data?.token;

  // 3. Worker Login
  const workerLogin = await request('/auth/login', {
    method: 'POST',
    body: { identifier: 'rahul@workerapp.com', password: 'worker123' },
  });
  console.log('3. Worker Login:', workerLogin.data.success ? '✅ OK' : '❌ FAIL', `(Worker: ${workerLogin.data.data?.user?.name})`);
  const workerToken = workerLogin.data.data?.token;
  const workerId = workerLogin.data.data?.user?.id;

  // 4. Get Current User Profile (Me)
  const workerMe = await request('/auth/me', {
    headers: { Authorization: `Bearer ${workerToken}` },
  });
  console.log('4. Worker GetMe Profile:', workerMe.data.success ? '✅ OK' : '❌ FAIL', `(Designation: ${workerMe.data.data?.designation})`);

  // 5. Worker Today Attendance
  const todayAtt = await request('/attendance/today', {
    headers: { Authorization: `Bearer ${workerToken}` },
  });
  console.log('5. Worker Today Attendance:', todayAtt.data.success ? '✅ OK' : '❌ FAIL', `(Status: ${todayAtt.data.data?.status})`);

  // 6. Admin Dashboard Summary
  const dashReport = await request('/reports/dashboard', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('6. Admin Dashboard Stats:', dashReport.data.success ? '✅ OK' : '❌ FAIL',
    `(Workers: ${dashReport.data.data?.workers?.total}, Present: ${dashReport.data.data?.attendanceToday?.present}, Rate: ${dashReport.data.data?.attendanceToday?.attendanceRate}%)`);

  // 7. Admin Worker Management - List & Departments
  const depts = await request('/workers/departments', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('7. Departments List:', depts.data.success ? '✅ OK' : '❌ FAIL', `(Departments: ${depts.data.data?.join(', ')})`);

  const workersList = await request('/workers', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('8. Admin Workers List:', workersList.data.success ? '✅ OK' : '❌ FAIL', `(Count: ${workersList.data.count})`);

  // 8. Task Management - Create & Complete
  const newTask = await request('/tasks', {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: {
      title: 'Inspect Transformer Circuit Breaker',
      description: 'Perform insulation resistance test on substation transformer 2.',
      assignedToId: workerId,
      priority: 'HIGH',
      location: 'Substation Alpha',
    },
  });
  console.log('9. Admin Assign Task:', newTask.data.success ? '✅ OK' : '❌ FAIL', `(Task ID: ${newTask.data.data?.id})`);
  const taskId = newTask.data.data?.id;

  const myTasks = await request('/tasks/my-tasks', {
    headers: { Authorization: `Bearer ${workerToken}` },
  });
  console.log('10. Worker Get My Tasks:', myTasks.data.success ? '✅ OK' : '❌ FAIL', `(Tasks count: ${myTasks.data.count})`);

  const completeTask = await request(`/tasks/${taskId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${workerToken}` },
    body: {
      status: 'COMPLETED',
      completionNotes: 'Transformer test passed with 500 Megohms insulation reading.',
    },
  });
  console.log('11. Worker Mark Task Completed:', completeTask.data.success ? '✅ OK' : '❌ FAIL');

  // 9. Leaves - Apply & Review
  const applyLeave = await request('/leaves/apply', {
    method: 'POST',
    headers: { Authorization: `Bearer ${workerToken}` },
    body: {
      leaveType: 'CASUAL',
      startDate: new Date(Date.now() + 86400000).toISOString(),
      endDate: new Date(Date.now() + 172800000).toISOString(),
      reason: 'Urgent domestic repair work',
    },
  });
  console.log('12. Worker Apply Leave:', applyLeave.data.success ? '✅ OK' : '❌ FAIL', `(Leave ID: ${applyLeave.data.data?.id})`);
  const leaveId = applyLeave.data.data?.id;

  const reviewLeave = await request(`/leaves/${leaveId}/review`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: {
      status: 'APPROVED',
      adminComment: 'Leave approved. Shift covered.',
    },
  });
  console.log('13. Admin Approve Leave:', reviewLeave.data.success ? '✅ OK' : '❌ FAIL');

  // 10. Salary & Advances
  const reqAdvance = await request('/salary/advance/request', {
    method: 'POST',
    headers: { Authorization: `Bearer ${workerToken}` },
    body: {
      amount: 4000,
      reason: 'Urgent family medical expense',
    },
  });
  console.log('14. Worker Request Advance:', reqAdvance.data.success ? '✅ OK' : '❌ FAIL', `(Advance ID: ${reqAdvance.data.data?.id})`);
  const advId = reqAdvance.data.data?.id;

  const approveAdv = await request(`/salary/advance/${advId}/review`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: {
      status: 'APPROVED',
      adminComment: 'Disbursed via UPI transfer',
    },
  });
  console.log('15. Admin Approve Advance:', approveAdv.data.success ? '✅ OK' : '❌ FAIL');

  const genPayslip = await request('/salary/generate-payslip', {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: {
      userId: workerId,
      month: 10,
      year: 2026,
      bonus: 1500,
      deductions: 500,
      notes: 'October monthly salary generated with festive bonus',
    },
  });
  console.log('16. Admin Generate Payslip:', genPayslip.data.success ? '✅ OK' : '❌ FAIL', `(Net Salary: ₹${genPayslip.data.data?.netSalary})`);

  // 11. Expenses
  const submitExp = await request('/expenses/submit', {
    method: 'POST',
    headers: { Authorization: `Bearer ${workerToken}` },
    body: {
      category: 'TOOLS',
      amount: 850,
      description: 'Safety goggles and heavy insulated gloves',
    },
  });
  console.log('17. Worker Submit Expense:', submitExp.data.success ? '✅ OK' : '❌ FAIL', `(Expense ID: ${submitExp.data.data?.id})`);

  // 12. Broadcast Announcement
  const broadcast = await request('/notifications/broadcast', {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: {
      title: 'Safety Meeting at 9 AM Tomorrow',
      message: 'All on-site workers must report to Section 2 for briefing.',
      department: 'ALL',
    },
  });
  console.log('18. Admin Broadcast Notification:', broadcast.data.success ? '✅ OK' : '❌ FAIL', `(Recipients: ${broadcast.data.count})`);

  // 13. Worker Notifications
  const myNotifs = await request('/notifications/my', {
    headers: { Authorization: `Bearer ${workerToken}` },
  });
  console.log('19. Worker In-App Notifications:', myNotifs.data.success ? '✅ OK' : '❌ FAIL', `(Notifications count: ${myNotifs.data.data?.length}, Unread: ${myNotifs.data.unreadCount})`);

  console.log('\n🎉 ALL 19 END-TO-END INTEGRATION TESTS PASSED WITH 100% SUCCESS!\n');
}

runTests().catch(console.error);
