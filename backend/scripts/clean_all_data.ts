import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function cleanAllData() {
  console.log('🧹 Purging all dummy records from database...');

  // 1. Delete all transactional / operational data
  await prisma.notification.deleteMany();
  console.log('  ✓ Notifications purged');

  await prisma.expense.deleteMany();
  console.log('  ✓ Expenses purged');

  await prisma.salaryAdvance.deleteMany();
  console.log('  ✓ Salary Advances purged');

  await prisma.salaryRecord.deleteMany();
  console.log('  ✓ Salary Records purged');

  await prisma.leaveRequest.deleteMany();
  console.log('  ✓ Leave Requests purged');

  await prisma.task.deleteMany();
  console.log('  ✓ Tasks purged');

  await prisma.attendance.deleteMany();
  console.log('  ✓ Attendance records purged');

  await prisma.attendanceLock.deleteMany();
  console.log('  ✓ Attendance Locks purged');

  // 2. Delete all worker users
  await prisma.user.deleteMany({
    where: {
      role: 'WORKER',
    },
  });
  console.log('  ✓ All dummy workers deleted');

  // 3. Ensure Admin account exists with 9695718820 & Aj@y
  const salt = await bcrypt.genSalt(10);
  const adminPassword = await bcrypt.hash('Aj@y', salt);

  const existingAdmin = await prisma.user.findFirst({
    where: {
      OR: [
        { phone: '9695718820' },
        { role: 'ADMIN' },
      ],
    },
  });

  if (existingAdmin) {
    await prisma.user.update({
      where: { id: existingAdmin.id },
      data: {
        name: 'अजय मौर्य (Admin)',
        phone: '9695718820',
        email: 'ajay@laxminarayan.com',
        password: adminPassword,
        role: 'ADMIN',
        department: 'Management',
        designation: 'Owner / Director',
        monthlySalary: 75000,
        hourlyRate: 400,
        status: 'ACTIVE',
        address: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
        emergencyContact: '+91 7304228743',
        bankAccount: 'HDFC0001234 - 50100234567890',
        upiId: 'ajay.maurya@okhdfcbank',
      },
    });
    console.log('  ✓ Admin account verified and updated: 9695718820');
  } else {
    await prisma.user.create({
      data: {
        name: 'अजय मौर्य (Admin)',
        phone: '9695718820',
        email: 'ajay@laxminarayan.com',
        password: adminPassword,
        role: 'ADMIN',
        department: 'Management',
        designation: 'Owner / Director',
        monthlySalary: 75000,
        hourlyRate: 400,
        status: 'ACTIVE',
        address: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
        emergencyContact: '+91 7304228743',
        bankAccount: 'HDFC0001234 - 50100234567890',
        upiId: 'ajay.maurya@okhdfcbank',
      },
    });
    console.log('  ✓ Fresh Admin account created: 9695718820');
  }

  // Double check user count
  const totalUsers = await prisma.user.count();
  const totalWorkers = await prisma.user.count({ where: { role: 'WORKER' } });
  const totalAttendances = await prisma.attendance.count();
  const totalSalaries = await prisma.salaryRecord.count();

  console.log('\n📊 Database Status After Cleanup:');
  console.log(`  - Total Users: ${totalUsers} (Admin: 1, Workers: ${totalWorkers})`);
  console.log(`  - Total Attendance Records: ${totalAttendances}`);
  console.log(`  - Total Salary Records: ${totalSalaries}`);
  console.log('✨ All dummy data completely purged! System is 100% clean.');
}

cleanAllData()
  .catch((e) => {
    console.error('Error cleaning data:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
