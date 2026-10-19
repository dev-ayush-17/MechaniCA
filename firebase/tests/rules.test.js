import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-mechanica',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  // The Admin SDK (FastAPI) bypasses rules, so seed with rules disabled.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'bookings/b1'), {
      customerId: 'cust',
      mechanicId: 'mech',
      status: 'confirmed',
      totalPaise: 70000,
    });
    await setDoc(doc(db, 'payments/p1'), { bookingId: 'b1', status: 'pending' });
  });
});

describe('firestore rules', () => {
  it('rules_deny_client_booking_write', async () => {
    const db = env.authenticatedContext('cust').firestore();
    await assertFails(updateDoc(doc(db, 'bookings/b1'), { status: 'paid' }));
    await assertFails(updateDoc(doc(db, 'bookings/b1'), { totalPaise: 1 }));
    await assertFails(setDoc(doc(db, 'bookings/b2'), { customerId: 'cust' }));
  });

  it('mechanic_cannot_write_booking_either', async () => {
    const db = env.authenticatedContext('mech').firestore();
    await assertFails(updateDoc(doc(db, 'bookings/b1'), { status: 'completed' }));
  });

  it('parties_can_read_their_booking', async () => {
    await assertSucceeds(getDoc(doc(env.authenticatedContext('cust').firestore(), 'bookings/b1')));
    await assertSucceeds(getDoc(doc(env.authenticatedContext('mech').firestore(), 'bookings/b1')));
  });

  it('strangers_cannot_read_a_booking', async () => {
    await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(), 'bookings/b1')));
  });

  it('rules_deny_client_payment_access', async () => {
    const db = env.authenticatedContext('cust').firestore();
    await assertFails(getDoc(doc(db, 'payments/p1')));
    await assertFails(updateDoc(doc(db, 'payments/p1'), { status: 'paid' }));
  });

  it('signed_out_users_read_nothing', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'bookings/b1')));
  });

  it('unknown_collections_are_denied', async () => {
    const db = env.authenticatedContext('cust').firestore();
    assert.ok(await assertFails(setDoc(doc(db, 'surprise/x'), { a: 1 })));
  });
});
