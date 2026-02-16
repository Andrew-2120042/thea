-- ============================================================
-- HYPE App - Supabase Database Schema
-- Run this in the Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(10) NOT NULL,
    active BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO categories (name, display_name, description, icon, order_index) VALUES
('confidence', 'Confidence', 'Build unshakeable self-belief', '💪', 0),
('self-care', 'Self-Care', 'Nurture your mind and body', '🌸', 1),
('boundaries', 'Boundaries', 'Honor your needs and limits', '🛡️', 2),
('abundance', 'Abundance', 'Attract prosperity and joy', '✨', 3),
('relationships', 'Relationships', 'Cultivate meaningful connections', '💕', 4),
('career', 'Career', 'Step into your professional power', '🚀', 5),
('healing', 'Healing', 'Release what no longer serves you', '🌿', 6),
('gratitude', 'Gratitude', 'Appreciate the beauty around you', '🙏', 7)
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- AFFIRMATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS affirmations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    text TEXT NOT NULL,
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('morning', 'night')),
    category VARCHAR(50) NOT NULL REFERENCES categories(name),
    active BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MORNING AFFIRMATIONS - Confidence (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I am powerful, capable, and worthy of everything I desire.', 'morning', 'confidence'),
('Today I show up as my most confident, authentic self.', 'morning', 'confidence'),
('I trust myself completely. My instincts are always right.', 'morning', 'confidence'),
('I am the main character of my own extraordinary life.', 'morning', 'confidence'),
('My potential is limitless and I am just getting started.', 'morning', 'confidence'),
('I walk into every room knowing my worth and owning my space.', 'morning', 'confidence'),
('I am enough exactly as I am, and I keep getting better.', 'morning', 'confidence'),
('Fear does not stop me. It just tells me what matters most.', 'morning', 'confidence'),
('I choose boldness. I choose visibility. I choose myself.', 'morning', 'confidence'),
('Every day I become more of the woman I was always meant to be.', 'morning', 'confidence');

-- MORNING AFFIRMATIONS - Self-Care (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I prioritise my wellbeing without guilt or apology.', 'morning', 'self-care'),
('My needs matter and I honour them with love and respect.', 'morning', 'self-care'),
('I give myself permission to rest, recharge, and receive.', 'morning', 'self-care'),
('My body is a temple and I treat it with the care it deserves.', 'morning', 'self-care'),
('I choose to fill my own cup first, so I can overflow for others.', 'morning', 'self-care'),
('I am gentle with myself on hard days and celebrate the good ones.', 'morning', 'self-care'),
('My mental health is a priority and I protect my peace fiercely.', 'morning', 'self-care'),
('I nourish my mind, body, and soul with intentional love daily.', 'morning', 'self-care'),
('Taking care of myself is the most productive thing I can do.', 'morning', 'self-care'),
('I deserve the same love and tenderness I give to others.', 'morning', 'self-care');

-- MORNING AFFIRMATIONS - Boundaries (10)
INSERT INTO affirmations (text, mode, category) VALUES
('My boundaries are an act of deep self-love and self-respect.', 'morning', 'boundaries'),
('I say no with confidence, grace, and zero guilt.', 'morning', 'boundaries'),
('I protect my energy as if my life depends on it — because it does.', 'morning', 'boundaries'),
('I choose relationships that honour and uplift who I am.', 'morning', 'boundaries'),
('Setting limits is a superpower, not a weakness.', 'morning', 'boundaries'),
('I release any obligation to explain or justify my boundaries.', 'morning', 'boundaries'),
('My time is precious and I invest it in what truly matters to me.', 'morning', 'boundaries'),
('I am allowed to outgrow people, places, and situations.', 'morning', 'boundaries'),
('I attract people who respect and celebrate my limits.', 'morning', 'boundaries'),
('The right people in my life understand and honour my no.', 'morning', 'boundaries');

-- MORNING AFFIRMATIONS - Abundance (10)
INSERT INTO affirmations (text, mode, category) VALUES
('Abundance flows to me naturally, freely, and endlessly.', 'morning', 'abundance'),
('I am a magnet for wealth, health, love, and opportunities.', 'morning', 'abundance'),
('Money comes to me easily and I manage it wisely.', 'morning', 'abundance'),
('There is more than enough success for everyone, including me.', 'morning', 'abundance'),
('I open myself to receive all the goodness life has to offer.', 'morning', 'abundance'),
('My dreams are not too big. The universe is big enough for all of them.', 'morning', 'abundance'),
('I am worthy of financial freedom and I am building it daily.', 'morning', 'abundance'),
('Every action I take today brings me closer to my abundant life.', 'morning', 'abundance'),
('I expect miracles because I am aligned with limitless possibility.', 'morning', 'abundance'),
('Prosperity is my natural state and I welcome it fully.', 'morning', 'abundance');

-- MORNING AFFIRMATIONS - Career (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I am brilliant, capable, and ready for every opportunity ahead.', 'morning', 'career'),
('My work matters and the world needs my unique gifts.', 'morning', 'career'),
('I lead with confidence and inspire others by example.', 'morning', 'career'),
('I am deserving of every promotion, raise, and recognition.', 'morning', 'career'),
('My success is inevitable and I embrace it without apology.', 'morning', 'career'),
('I show up as a leader in every room I walk into.', 'morning', 'career'),
('My ideas are valuable and my voice deserves to be heard.', 'morning', 'career'),
('I am building a career that lights me up and pays me well.', 'morning', 'career'),
('Every challenge at work is preparing me for my next level.', 'morning', 'career'),
('I am the right person for this role, this moment, this opportunity.', 'morning', 'career');

-- NIGHT AFFIRMATIONS - Healing (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I release today with love and welcome tomorrow with hope.', 'night', 'healing'),
('I am healing more than I know. My progress is real.', 'night', 'healing'),
('I forgive myself for anything I think I did wrong today.', 'night', 'healing'),
('Every day I let go of what no longer serves my highest good.', 'night', 'healing'),
('I am safe to feel my emotions. They are messengers, not enemies.', 'night', 'healing'),
('My wounds are becoming my wisdom. I trust the process.', 'night', 'healing'),
('I release the weight of the day and rest in my wholeness.', 'night', 'healing'),
('Healing is not linear and I honour every step of my journey.', 'night', 'healing'),
('I am stronger than anything I have ever been through.', 'night', 'healing'),
('As I sleep, my body, mind, and soul restore and renew.', 'night', 'healing');

-- NIGHT AFFIRMATIONS - Gratitude (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I am grateful for everything this day brought — the lessons and the blessings.', 'night', 'gratitude'),
('My life is full of beautiful moments I sometimes forget to notice.', 'night', 'gratitude'),
('I am thankful for my body, my mind, and the life I get to live.', 'night', 'gratitude'),
('Every breath I take is a gift and I receive it with appreciation.', 'night', 'gratitude'),
('Gratitude shifts everything. I choose to see the good tonight.', 'night', 'gratitude'),
('I am proud of myself for showing up today in whatever way I could.', 'night', 'gratitude'),
('Thank you, universe, for all that I have and all that is coming.', 'night', 'gratitude'),
('The more grateful I am, the more beauty I attract into my life.', 'night', 'gratitude'),
('I close this day in peace, knowing I am exactly where I need to be.', 'night', 'gratitude'),
('I rest in gratitude for my growth, my health, and my becoming.', 'night', 'gratitude');

-- NIGHT AFFIRMATIONS - Self-Care (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I have done enough today. I am enough today.', 'night', 'self-care'),
('I deserve restful, restorative, deeply peaceful sleep.', 'night', 'self-care'),
('Tonight I choose to be kind to myself above all else.', 'night', 'self-care'),
('I release any guilt about what I did not accomplish today.', 'night', 'self-care'),
('My rest is just as important as my hustle. Both are sacred.', 'night', 'self-care'),
('I take care of myself tonight so I can show up powerfully tomorrow.', 'night', 'self-care'),
('I honour my body by giving it the rest it has earned.', 'night', 'self-care'),
('The most loving thing I can do right now is let myself rest.', 'night', 'self-care'),
('I breathe in peace and exhale any tension still living in my body.', 'night', 'self-care'),
('I am gentle with myself. Tomorrow is a fresh start.', 'night', 'self-care');

-- NIGHT AFFIRMATIONS - Confidence (10)
INSERT INTO affirmations (text, mode, category) VALUES
('I am proud of everything I am and everything I am still becoming.', 'night', 'confidence'),
('Today I showed up. That is enough to be proud of.', 'night', 'confidence'),
('I wake up tomorrow even more powerful, clear, and ready.', 'night', 'confidence'),
('I am not defined by my mistakes — I am shaped by my resilience.', 'night', 'confidence'),
('Confidence is not the absence of fear. It is choosing myself anyway.', 'night', 'confidence'),
('I lay down my insecurities with the day and wake with courage.', 'night', 'confidence'),
('Every day I am building an unshakeable belief in myself.', 'night', 'confidence'),
('The challenges of today have made me stronger for tomorrow.', 'night', 'confidence'),
('I trust myself to handle whatever tomorrow brings.', 'night', 'confidence'),
('I am becoming the woman I always dreamed of being.', 'night', 'confidence');

-- ============================================================
-- HYPE MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS hype_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    text TEXT NOT NULL,
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('morning', 'night', 'general')),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO hype_messages (text, mode) VALUES
-- Morning Hype
('YES QUEEN! You just set the tone for your entire day! 🔥', 'morning'),
('That''s the energy! The universe just heard you loud and clear! ✨', 'morning'),
('Look at you showing up for yourself before the day even starts! 👑', 'morning'),
('She woke up and chose POWER. That''s you, babe. 💜', 'morning'),
('You just unlocked a new version of yourself. Level UP! 🚀', 'morning'),
('This is your superpower — speaking your truth out loud. Keep going! 🌟', 'morning'),
('The woman who does this every morning? Unstoppable. That''s YOU. 🔥', 'morning'),
('Science says speaking affirmations out loud rewires your brain. You just did that! 🧠✨', 'morning'),
('Not everyone has the courage to do what you just did. You''re different. 💫', 'morning'),
('Your future self is PROUD of you right now. Keep going. 👑', 'morning'),
('You came, you spoke, you conquered. Morning check-in: DONE! ✅', 'morning'),
('That right there? That''s why you''re going to have an incredible day. 🌅', 'morning'),

-- Night Hype
('You showed up for yourself today and THAT is everything. 🌙', 'night'),
('Rest well, queen. Tomorrow you do it all over again. 💜', 'night'),
('Look at you — ending the day with intentionality. Most people won''t. 🌟', 'night'),
('Your consistency is your superpower. Another day, another win. 🔥', 'night'),
('You processed today with grace. That takes real strength. 💫', 'night'),
('This is the practice. You''re building something powerful. Night by night. ✨', 'night'),
('Sweet dreams, powerful soul. You deserve every good thing coming your way. 🌙', 'night'),
('The version of you that did this tonight? She''s the one who changes everything. 👑', 'night'),
('Ending the day with self-love is a radical act. You''re radical. 💜', 'night'),
('You spoke your worth into existence tonight. Now go rest and let it settle. 🌸', 'night');

-- ============================================================
-- USER ACTIVITY TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS user_activity (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    affirmation_id UUID REFERENCES affirmations(id),
    hype_message_id UUID REFERENCES hype_messages(id),
    mode VARCHAR(20) NOT NULL,
    completed BOOLEAN DEFAULT true,
    repeated BOOLEAN DEFAULT false,
    feeling_after TEXT,
    voice_level_reached INTEGER DEFAULT 0,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS user_activity_device_date ON user_activity(device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS user_activity_mode ON user_activity(mode);

-- ============================================================
-- ROW LEVEL SECURITY (Optional - enable if needed)
-- ============================================================
-- ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE affirmations ENABLE ROW LEVEL SECURITY;

-- Allow all reads on affirmations and categories (public content)
-- CREATE POLICY "Public read affirmations" ON affirmations FOR SELECT USING (true);
-- CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
-- CREATE POLICY "Public read hype_messages" ON hype_messages FOR SELECT USING (true);

-- Allow users to insert/read their own activity by device_id
-- CREATE POLICY "User activity by device" ON user_activity
--   FOR ALL USING (device_id = current_setting('request.headers')::json->>'x-device-id');
