import bcrypt from 'bcryptjs';
import { prisma } from './prisma';

async function main() {
  console.log('🌱 Starting Clean Database Setup for Shree Laxminarayan Aluminium Works...');

  // Clean previous data
  await prisma.notification.deleteMany();
  await prisma.expense.deleteMany();
  await prisma.salaryAdvance.deleteMany();
  await prisma.salaryRecord.deleteMany();
  await prisma.leaveRequest.deleteMany();
  await prisma.task.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.attendanceLock.deleteMany();
  await prisma.user.deleteMany();

  const salt = await bcrypt.genSalt(10);
  const adminPassword = await bcrypt.hash('Aj@y', salt);

  // 1. Create Admin User
  const admin = await prisma.user.create({
    data: {
      name: 'अजय मौर्य (Admin)',
      email: 'ajay@laxminarayan.com',
      phone: '9695718820',
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

  console.log(`✅ Clean Admin Account Created: ${admin.phone} (Name: ${admin.name})`);
  console.log('✨ Database is initialized with 0 dummy workers and 0 dummy records.');
}

main()
  .catch((e) => {
    console.error('Error in seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
