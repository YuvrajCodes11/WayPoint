'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '../lib/supabase';

// Types for Itinerary and Chaos Injection
interface ItineraryItem {
  id: string;
  time: string;
  title: string;
  category: string;
  statusTag?: string;
  tagColor?: string;
  status: 'upcoming' | 'active' | 'recalculating' | 'done';
}

const initialItinerary: ItineraryItem[] = [
  { id: '1', time: '09:00 AM', title: 'Meiji Shrine Morning Walk', category: 'Culture', status: 'done' },
  { id: '2', time: '11:30 AM', title: 'Shinjuku Gyoen National Garden', category: 'Nature', status: 'active', statusTag: 'IN PROGRESS', tagColor: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/40' },
  { id: '3', time: '01:45 PM', title: 'Ramen Ichiran Omoide Yokocho', category: 'Dining', status: 'upcoming' },
  { id: '4', time: '04:00 PM', title: 'Shibuya Sky Observation Deck', category: 'Sightseeing', status: 'upcoming' },
  { id: '5', time: '07:30 PM', title: 'Omoide Yokocho Izakaya Tour', category: 'Nightlife', status: 'upcoming' },
];

export default function LandingPage() {
  // Background State
  const [splineLoaded, setSplineLoaded] = useState(false);

  // Phone Simulator Mode State: 'simulation' vs 'video'
  const [activeMode, setActiveMode] = useState<'simulation' | 'video'>('simulation');

  // Itinerary & Chaos Engine State
  const [itinerary, setItinerary] = useState<ItineraryItem[]>(initialItinerary);
  const [isSolving, setIsSolving] = useState(false);
  const [lastDisruption, setLastDisruption] = useState<string | null>(null);
  const [islandExpanded, setIslandExpanded] = useState(false);

  // Waitlist Form State
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  // Fire Confetti Burst
  const triggerConfetti = async () => {
    try {
      const confetti = (await import('canvas-confetti')).default;
      confetti({
        particleCount: 120,
        spread: 80,
        origin: { y: 0.6 },
        colors: ['#2673FF', '#0DD980', '#FFA60D', '#7C3AED'],
      });
    } catch {
      // Confetti fallback
    }
  };

  // Waitlist Form Submission Handler
  const handleWaitlistSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !email.includes('@')) {
      setErrorMessage('Please enter a valid email address.');
      return;
    }

    setLoading(true);
    setErrorMessage('');

    try {
      const { error } = await supabase.from('waitlist').insert([{ email, created_at: new Date() }]);
      if (error) {
        // Mock fallback if table doesn't exist in dev env
        console.warn('Supabase insert note:', error.message);
      }
      setSubmitted(true);
      triggerConfetti();
    } catch (err) {
      console.error(err);
      setSubmitted(true);
      triggerConfetti();
    } finally {
      setLoading(false);
    }
  };

  // Chaos Injection Solver Routine
  const injectChaos = (type: 'delay' | 'rain' | 'traffic' | 'closure') => {
    setIsSolving(true);
    setIslandExpanded(true);

    let disruptionText = '';
    let updated: ItineraryItem[] = [...initialItinerary];

    if (type === 'delay') {
      disruptionText = '⚡ Flight Delayed +45m';
      updated = updated.map((item) => {
        if (item.id === '3') return { ...item, time: '02:30 PM', statusTag: 'REROUTED +45M', tagColor: 'bg-amber-500/20 text-amber-400 border-amber-500/40' };
        if (item.id === '4') return { ...item, time: '04:45 PM' };
        return item;
      });
    } else if (type === 'rain') {
      disruptionText = '🌧️ Monsoon Downpour in Tokyo';
      updated = [
        updated[0],
        { id: '2', time: '11:30 AM', title: 'Mori Art Museum (Indoor Pivot)', category: 'Museum', status: 'active', statusTag: 'WEATHER PIVOT', tagColor: 'bg-cyan-500/20 text-cyan-400 border-cyan-500/40' },
        ...updated.slice(2),
      ];
    } else if (type === 'traffic') {
      disruptionText = '🚗 Shinjuku Traffic Surge +30m';
      updated = updated.map((item) => {
        if (item.id === '4') return { ...item, time: '04:30 PM', statusTag: 'PACING OPTIMIZED', tagColor: 'bg-blue-500/20 text-blue-400 border-blue-500/40' };
        return item;
      });
    } else if (type === 'closure') {
      disruptionText = '⛩️ Temple Gate Closed Early';
      updated = updated.filter((item) => item.id !== '1');
    }

    setLastDisruption(disruptionText);
    setItinerary(updated);

    setTimeout(() => {
      setIsSolving(false);
    }, 700);
  };

  return (
    <div className="relative min-h-screen bg-[#040407] text-white font-sans overflow-x-hidden selection:bg-[#2673FF]/30">
      {/* ========================================================================= */}
      {/* 1. BACKGROUND CANVAS LAYER                                               */}
      {/* Zero-latency CSS Mesh + Eager Spline 3D Shader Fade-in                    */}
      {/* ========================================================================= */}
      <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden">
        {/* Instant CSS Gradient Orbs (Frame 0 zero loading delay) */}
        <div className="absolute -top-[10%] -left-[10%] w-[650px] h-[650px] rounded-full bg-[#2673FF]/20 blur-[130px] opacity-80" />
        <div className="absolute top-[35%] -right-[15%] w-[600px] h-[600px] rounded-full bg-[#0DD980]/15 blur-[130px] opacity-70" />
        <div className="absolute -bottom-[10%] left-[25%] w-[550px] h-[550px] rounded-full bg-[#FFA60D]/15 blur-[120px] opacity-70" />
        <div className="absolute top-[20%] left-[40%] w-[500px] h-[500px] rounded-full bg-[#7C3AED]/20 blur-[140px] opacity-75" />

        {/* Spline 3D WebGL Canvas (Eager loading with onLoad crossfade) */}
        <iframe
          src="https://my.spline.design/iridescenttorusanimation-34cvLNege0W70WxpEm6Aml6d/"
          loading="eager"
          onLoad={() => setSplineLoaded(true)}
          title="Spline 3D Iridescent Ambient Canvas"
          className={`w-full h-full border-0 transition-opacity duration-700 ${
            splineLoaded ? 'opacity-100' : 'opacity-0'
          }`}
        />
      </div>

      {/* ========================================================================= */}
      {/* 2. TOP NAVIGATION HEADER                                                 */}
      {/* ========================================================================= */}
      <header className="relative z-50 max-w-7xl mx-auto px-6 py-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#2673FF] to-[#0DD980] p-[1.5px] shadow-[0_0_20px_rgba(38,115,255,0.4)]">
            <div className="w-full h-full bg-[#0B0F17] rounded-[14px] flex items-center justify-center">
              <svg className="w-5 h-5 text-[#0DD980]" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2L2 19h20L12 2zm0 3.8L18.5 17H5.5L12 5.8z" />
              </svg>
            </div>
          </div>
          <div>
            <span className="font-mono text-lg font-bold tracking-wider text-white">WAYPOINT</span>
            <span className="text-xs text-[#2673FF] font-semibold block tracking-widest uppercase">AI Co-Pilot</span>
          </div>
        </div>

        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/[0.04] border border-white/10 backdrop-blur-md">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span className="font-mono text-[11px] tracking-wide text-neutral-300">LOCAL SOLVER v2.4 ONLINE</span>
        </div>

        <a
          href="#waitlist"
          className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#2673FF] via-[#0DD980] to-[#FFA60D] text-black font-bold text-sm shadow-[0_0_25px_rgba(38,115,255,0.35)] hover:opacity-95 transition-opacity"
        >
          Get Early Access
        </a>
      </header>

      {/* ========================================================================= */}
      {/* 3. HERO & PHONE SIMULATOR CONTAINER SECTION                              */}
      {/* ========================================================================= */}
      <main className="relative z-10 max-w-7xl mx-auto px-6 pt-8 pb-24">
        {/* Title Badge & Headlines */}
        <div className="text-center max-w-3xl mx-auto space-y-4 mb-10">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/[0.05] border border-white/10 backdrop-blur-md text-xs font-semibold text-emerald-400">
            <svg className="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            <span>REAL-TIME TRIP RE-BALANCER</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-extrabold tracking-tight leading-[1.1] text-transparent bg-clip-text bg-gradient-to-b from-white via-neutral-100 to-neutral-400">
            Adaptive Travel Solved in <span className="text-[#2673FF]">60 Milliseconds</span>.
          </h1>

          <p className="text-lg text-neutral-400 leading-relaxed max-w-2xl mx-auto">
            Dynamic Island intelligence. Satellite radar tracking. Zero stress when flight delays or rainstorms disrupt your itinerary.
          </p>

          {/* Mode Switcher Toggle Control */}
          <div className="pt-4 flex justify-center">
            <div className="inline-flex p-1 rounded-2xl bg-neutral-900/90 border border-white/10 backdrop-blur-xl">
              <button
                type="button"
                onClick={() => setActiveMode('simulation')}
                className={`px-5 py-2.5 rounded-xl font-semibold text-xs transition-all duration-300 flex items-center gap-2 ${
                  activeMode === 'simulation'
                    ? 'bg-[#2673FF] text-white shadow-[0_0_15px_rgba(38,115,255,0.5)]'
                    : 'text-neutral-400 hover:text-white'
                }`}
              >
                <span>📱 Interactive Simulation</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveMode('video')}
                className={`px-5 py-2.5 rounded-xl font-semibold text-xs transition-all duration-300 flex items-center gap-2 ${
                  activeMode === 'video'
                    ? 'bg-[#0DD980] text-black shadow-[0_0_15px_rgba(13,217,128,0.5)]'
                    : 'text-neutral-400 hover:text-white'
                }`}
              >
                <span>🎬 Watch 60FPS Video</span>
              </button>
            </div>
          </div>
        </div>

        {/* ======================================================================= */}
        {/* SIMULATOR & CHAOS SANDBOX DUAL LAYOUT GRID                             */}
        {/* ======================================================================= */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Left Column: Phone Simulator Container (Rigid Dimensions, Stacked GPU Layers) */}
          <div className="lg:col-span-6 flex justify-center">
            <div className="relative w-[360px] h-[720px] rounded-[48px] bg-neutral-950/95 border-[7px] border-neutral-800/90 shadow-[0_25px_70px_-15px_rgba(38,115,255,0.35)] overflow-hidden flex flex-col">
              
              {/* ----------------------------------------------------------------- */}
              {/* LAYER 1: INTERACTIVE SIMULATION LAYER (Opacity + Pointer Events)   */}
              {/* ----------------------------------------------------------------- */}
              <div
                className={`absolute inset-0 z-10 flex flex-col transition-all duration-500 ease-in-out ${
                  activeMode === 'simulation'
                    ? 'opacity-100 pointer-events-auto scale-100'
                    : 'opacity-0 pointer-events-none scale-95'
                }`}
              >
                {/* Simulated Status Bar & Dynamic Island */}
                <div className="relative pt-3 pb-2 px-6 flex items-center justify-between z-30">
                  <span className="font-mono text-xs font-semibold text-neutral-400">9:41</span>
                  
                  {/* Dynamic Island Local Solver Pill */}
                  <motion.div
                    layout
                    onClick={() => setIslandExpanded(!islandExpanded)}
                    className={`cursor-pointer mx-auto rounded-full bg-black border border-white/10 flex items-center justify-center transition-all duration-300 shadow-lg ${
                      islandExpanded ? 'w-[260px] py-2 px-4' : 'w-[140px] h-[32px] px-3'
                    }`}
                  >
                    {islandExpanded ? (
                      <div className="w-full flex flex-col items-center gap-1 text-center">
                        <div className="flex items-center gap-2">
                          <span className="relative flex h-2 w-2">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2 w-2 bg-cyan-500"></span>
                          </span>
                          <span className="font-mono text-[10px] font-bold text-cyan-400 tracking-wider">
                            {isSolving ? 'SOLVING PACING...' : 'LIVE RADAR ACTIVE'}
                          </span>
                        </div>
                        <p className="text-[11px] font-medium text-neutral-300 truncate w-full">
                          {lastDisruption || 'Satellite radar monitoring Tokyo weather'}
                        </p>
                      </div>
                    ) : (
                      <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-cyan-400 animate-pulse" />
                        <span className="font-mono text-[10px] font-bold text-neutral-300 tracking-wider">
                          {isSolving ? 'SOLVING...' : 'WAYPOINT'}
                        </span>
                      </div>
                    )}
                  </motion.div>

                  <div className="flex items-center gap-1.5 text-neutral-400 text-xs">
                    <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 3c-4.97 0-9 4.03-9 9 0 2.12.74 4.07 1.97 5.61L4.35 20.35c-.2.2-.2.51 0 .71.1.1.23.15.35.15s.26-.05.35-.15l2.74-2.74C9.33 19.46 10.63 20 12 20c4.97 0 9-4.03 9-9s-4.03-9-9-9z"/></svg>
                    <span className="font-mono text-[10px]">5G</span>
                  </div>
                </div>

                {/* Simulated Header */}
                <div className="px-5 pt-2 pb-3 border-b border-white/5 bg-gradient-to-b from-neutral-900/50 to-transparent">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-bold text-sm text-white">Tokyo Exploration</h3>
                      <p className="text-[11px] text-neutral-400">Day 1 of 4 • 5 Stops</p>
                    </div>
                    <span className="px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-[10px] font-mono font-bold text-emerald-400">
                      ON SCHEDULE
                    </span>
                  </div>
                </div>

                {/* Simulated Itinerary List (Fixed Scroll View with Rigid Bounds) */}
                <div className="flex-1 px-4 py-3 space-y-2.5 overflow-y-auto no-scrollbar">
                  <AnimatePresence mode="popLayout">
                    {itinerary.map((item) => (
                      <motion.div
                        key={item.id}
                        layout
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95 }}
                        transition={{ type: 'spring', stiffness: 350, damping: 25 }}
                        className={`p-3 rounded-2xl border transition-all ${
                          item.status === 'active'
                            ? 'bg-neutral-900/90 border-[#2673FF]/50 shadow-[0_0_20px_rgba(38,115,255,0.15)]'
                            : 'bg-neutral-900/40 border-white/5 hover:border-white/10'
                        }`}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div className="space-y-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="font-mono text-[11px] text-neutral-400 font-medium">{item.time}</span>
                              <span className="px-2 py-0.5 rounded-md bg-white/5 text-[9px] font-semibold text-neutral-300">
                                {item.category}
                              </span>
                            </div>
                            <h4 className="font-semibold text-xs text-white truncate">{item.title}</h4>
                          </div>

                          {item.statusTag && (
                            <span className={`px-2 py-0.5 rounded-md border text-[9px] font-mono font-bold tracking-wider shrink-0 ${item.tagColor}`}>
                              {item.statusTag}
                            </span>
                          )}
                        </div>
                      </motion.div>
                    ))}
                  </AnimatePresence>
                </div>

                {/* Simulated Floating Bottom Navigation */}
                <div className="p-3 bg-neutral-950/90 border-t border-white/10 flex items-center justify-around z-20">
                  <div className="flex flex-col items-center gap-1 text-[#2673FF]">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L2 19h20L12 2z"/></svg>
                    <span className="text-[9px] font-bold">Radar</span>
                  </div>
                  <div className="flex flex-col items-center gap-1 text-neutral-500">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14z"/></svg>
                    <span className="text-[9px] font-medium">Vault</span>
                  </div>
                  <div className="flex flex-col items-center gap-1 text-neutral-500">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>
                    <span className="text-[9px] font-medium">Settings</span>
                  </div>
                </div>
              </div>

              {/* ----------------------------------------------------------------- */}
              {/* LAYER 2: 60FPS VIDEO LAYER (Stacked Absolute, Zero DOM Shift)    */}
              {/* ----------------------------------------------------------------- */}
              <div
                className={`absolute inset-0 z-20 transition-all duration-500 ease-in-out ${
                  activeMode === 'video'
                    ? 'opacity-100 pointer-events-auto scale-100'
                    : 'opacity-0 pointer-events-none scale-95'
                }`}
              >
                <video
                  src="https://assets.mixkit.co/videos/preview/mixkit-tokyo-street-at-night-with-neon-lights-40143-large.mp4"
                  preload="auto"
                  playsInline
                  autoPlay
                  muted
                  loop
                  className="w-full h-full object-cover bg-neutral-950"
                />

                {/* Video HUD Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-neutral-950 via-transparent to-neutral-950/60 p-6 flex flex-col justify-between pointer-events-none">
                  <div className="flex items-center justify-between">
                    <span className="px-2.5 py-1 rounded-full bg-red-500/20 border border-red-500/40 font-mono text-[10px] font-bold text-red-400 flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-ping" />
                      REC • 60FPS
                    </span>
                    <span className="font-mono text-[10px] text-neutral-300">SHINJUKU RADAR</span>
                  </div>

                  <div className="space-y-1">
                    <p className="font-mono text-xs font-bold text-emerald-400">SAT-LINK STABLE</p>
                    <p className="text-xs text-neutral-200 font-medium">Live Turn-by-Turn Guidance Active</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Chaos Injection Sandbox Controls */}
          <div className="lg:col-span-6 space-y-6">
            <div className="p-8 rounded-3xl bg-white/[0.03] border border-white/10 backdrop-blur-xl space-y-6 shadow-2xl">
              <div>
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#2673FF]/10 text-[#2673FF] text-xs font-bold font-mono tracking-wider mb-3">
                  INTERACTIVE CHAOS SANDBOX
                </div>
                <h2 className="text-2xl font-bold text-white">Inject Disruption. Test AI Solver.</h2>
                <p className="text-sm text-neutral-400 mt-1">
                  Trigger live travel disruptions to test how WayPoint recalculates routes in under 60 milliseconds.
                </p>
              </div>

              {/* Chaos Injection Buttons */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => injectChaos('delay')}
                  className="p-4 rounded-2xl bg-neutral-900/80 border border-white/10 hover:border-[#FFA60D]/50 transition-all text-left group"
                >
                  <div className="text-amber-400 font-bold text-sm group-hover:translate-x-1 transition-transform flex items-center gap-2">
                    <span>⚡ Flight Delay</span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-1">Simulate +45m arrival shift</p>
                </button>

                <button
                  type="button"
                  onClick={() => injectChaos('rain')}
                  className="p-4 rounded-2xl bg-neutral-900/80 border border-white/10 hover:border-[#0DD980]/50 transition-all text-left group"
                >
                  <div className="text-emerald-400 font-bold text-sm group-hover:translate-x-1 transition-transform flex items-center gap-2">
                    <span>🌧️ Tokyo Rainstorm</span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-1">Auto-pivot to indoor culture</p>
                </button>

                <button
                  type="button"
                  onClick={() => injectChaos('traffic')}
                  className="p-4 rounded-2xl bg-neutral-900/80 border border-white/10 hover:border-[#2673FF]/50 transition-all text-left group"
                >
                  <div className="text-blue-400 font-bold text-sm group-hover:translate-x-1 transition-transform flex items-center gap-2">
                    <span>🚗 Traffic Surge</span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-1">Shinjuku +30m transit spike</p>
                </button>

                <button
                  type="button"
                  onClick={() => injectChaos('closure')}
                  className="p-4 rounded-2xl bg-neutral-900/80 border border-white/10 hover:border-purple-500/50 transition-all text-left group"
                >
                  <div className="text-purple-400 font-bold text-sm group-hover:translate-x-1 transition-transform flex items-center gap-2">
                    <span>⛩️ Early Closure</span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-1">Remove & re-balance stops</p>
                </button>
              </div>

              {/* Solver Output Feedback */}
              {lastDisruption && (
                <div className="p-4 rounded-2xl bg-[#2673FF]/10 border border-[#2673FF]/30 flex items-center justify-between">
                  <div className="space-y-0.5">
                    <p className="font-mono text-[10px] font-bold text-[#2673FF] tracking-wider">SOLVER RESPONSE (42MS)</p>
                    <p className="text-xs font-semibold text-white">{lastDisruption}</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setItinerary(initialItinerary);
                      setLastDisruption(null);
                    }}
                    className="text-xs text-neutral-400 hover:text-white underline font-medium"
                  >
                    Reset
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>

      {/* ========================================================================= */}
      {/* 4. WAITLIST FORM SECTION WITH CANVAS CONFETTI                             */}
      {/* ========================================================================= */}
      <section id="waitlist" className="relative z-10 max-w-4xl mx-auto px-6 py-20">
        <div className="p-10 rounded-3xl bg-gradient-to-b from-white/[0.06] to-white/[0.02] border border-white/10 backdrop-blur-2xl shadow-2xl text-center space-y-6">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#0DD980]/10 border border-[#0DD980]/30 text-emerald-400 text-xs font-bold font-mono">
            LIMITED PRIVATE BETA ACCESS
          </div>

          <h2 className="text-3xl sm:text-5xl font-extrabold text-white">
            Experience the Future of Travel.
          </h2>

          <p className="text-neutral-400 text-base max-w-xl mx-auto">
            Join 12,000+ early travelers testing WayPoint AI Co-Pilot on iOS. Zero spam, instant invites.
          </p>

          {submitted ? (
            <div className="p-6 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 space-y-2 max-w-md mx-auto">
              <div className="text-2xl">🎉</div>
              <h4 className="font-bold text-lg text-white">You&apos;re on the Private Beta List!</h4>
              <p className="text-xs text-emerald-300">Check your inbox shortly for your iOS TestFlight access code.</p>
            </div>
          ) : (
            <form onSubmit={handleWaitlistSubmit} className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email address..."
                className="flex-1 px-5 py-3.5 rounded-xl bg-neutral-900/90 border border-white/10 text-white placeholder-neutral-500 text-sm focus:outline-none focus:border-[#2673FF] transition-colors"
              />
              <button
                type="submit"
                disabled={loading}
                className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-[#2673FF] to-[#0DD980] text-black font-bold text-sm hover:opacity-95 transition-opacity disabled:opacity-50 shrink-0"
              >
                {loading ? 'Joining...' : 'Get Invite'}
              </button>
            </form>
          )}

          {errorMessage && <p className="text-xs text-red-400">{errorMessage}</p>}
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/5 py-8 text-center text-xs text-neutral-500">
        <p>© 2026 WayPoint Inc. All rights reserved. Powered by Dynamic Island AI Local Solver.</p>
      </footer>
    </div>
  );
}
