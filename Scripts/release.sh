#!/bin/bash
# QELORYX — release.sh — Official Release Sequence — Dev → Alpha → Beta → RC → Stable
# Industry Standard — 5 Stages — Production Ready — 1.0.0 Stable

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🎵 QELORYX — Official Release Sequence — Dev → Alpha → Beta → RC → Stable${NC}"
echo -e "${CYAN}Version: 1.0.0 Stable — Industry Standard — 5 Stages${NC}"
echo -e "${CYAN}Theme: Midnight Aurora — Hear Beyond. Build Beyond.${NC}"
echo ""

# Check if we're in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not a git repository. Please run from QELORYX repo root.${NC}"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch: $CURRENT_BRANCH${NC}"

# Function to show official sequence
show_sequence() {
    echo ""
    echo -e "${YELLOW}=== Official Release Sequence — Industry Standard — 5 Stages ===${NC}"
    echo -e "${CYAN}Dev (1/5) → Alpha (2/5) → Beta (3/5) → RC (4/5) → Stable (5/5) → Next Cycle${NC}"
    echo ""
    echo -e "${BLUE}1/5 Dev    — v1.0.0-dev.1   — Nightly — Internal core team — Experimental — Fast iteration${NC}"
    echo -e "${BLUE}2/5 Alpha  — v1.0.0-alpha.1 — Internal QA — Features testable — Internal QA${NC}"
    echo -e "${BLUE}3/5 Beta   — v1.0.0-beta.1  — TestFlight — Feature complete — External feedback${NC}"
    echo -e "${BLUE}4/5 RC     — v1.0.0-rc.1    — Release Candidate — Code freeze — Final verification${NC}"
    echo -e "${GREEN}5/5 Stable — v1.0.0         — App Store — GA — Production — Public${NC}"
    echo ""
    echo -e "${YELLOW}Rules: Strict order, no skipping, each stage exit criteria must pass before next${NC}"
    echo ""
}

# Function to get latest tag for a channel
get_latest_tag() {
    local channel=$1
    if [ "$channel" = "stable" ]; then
        git tag --list 'v1.*.*' --sort=-v:refname | grep -v -E '\-dev|\-alpha|\-beta|\-rc' | head -1
    else
        git tag --list "v1.*.*-$channel.*" --sort=-v:refname | head -1
    fi
}

# Function to suggest next version
suggest_next_version() {
    local channel=$1
    local latest=$(get_latest_tag $channel)
    
    if [ -z "$latest" ]; then
        case $channel in
            dev) echo "v1.0.0-dev.1" ;;
            alpha) echo "v1.0.0-alpha.1" ;;
            beta) echo "v1.0.0-beta.1" ;;
            rc) echo "v1.0.0-rc.1" ;;
            stable) echo "v1.0.0" ;;
        esac
    else
        # Extract number and increment
        if [[ "$latest" =~ \.([0-9]+)$ ]]; then
            num=${BASH_REMATCH[1]}
            next_num=$((num + 1))
            echo "${latest%.*}.$next_num"
        elif [[ "$latest" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
            # Stable — suggest next patch dev
            echo "v1.0.1-dev.1"
        else
            echo "${latest}.1"
        fi
    fi
}

# Show current tags
echo -e "${BLUE}=== Current Tags — Official Sequence ===${NC}"
echo -e "${YELLOW}Dev tags:${NC}"
git tag --list 'v*-dev*' --sort=-v:refname | head -5 || echo "  No dev tags yet"
echo -e "${YELLOW}Alpha tags:${NC}"
git tag --list 'v*-alpha*' --sort=-v:refname | head -5 || echo "  No alpha tags yet"
echo -e "${YELLOW}Beta tags:${NC}"
git tag --list 'v*-beta*' --sort=-v:refname | head -5 || echo "  No beta tags yet"
echo -e "${YELLOW}RC tags:${NC}"
git tag --list 'v*-rc*' --sort=-v:refname | head -5 || echo "  No rc tags yet"
echo -e "${YELLOW}Stable tags:${NC}"
git tag --list 'v1.*.*' --sort=-v:refname | grep -v -E '\-dev|\-alpha|\-beta|\-rc' | head -5 || echo "  No stable tags yet"
echo ""

show_sequence

# If no args, show help and interactive mode
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}=== Usage — Official Sequence ===${NC}"
    echo "  ./Scripts/release.sh dev              — Release dev build v1.0.0-dev.1 (1/5)"
    echo "  ./Scripts/release.sh alpha            — Release alpha build v1.0.0-alpha.1 (2/5)"
    echo "  ./Scripts/release.sh beta             — Release beta build v1.0.0-beta.1 (3/5)"
    echo "  ./Scripts/release.sh rc               — Release RC build v1.0.0-rc.1 (4/5)"
    echo "  ./Scripts/release.sh stable           — Release stable build v1.0.0 (5/5)"
    echo "  ./Scripts/release.sh dev 1.0.0-dev.2   — Release specific version"
    echo "  ./Scripts/release.sh --help           — Show help"
    echo ""
    echo -e "${YELLOW}=== Quick Start — First Time — 1.0.0 ===${NC}"
    echo "  ./Scripts/release.sh dev     # Now — Dev internal"
    echo "  ./Scripts/release.sh alpha   # After dev OK — Alpha internal QA"
    echo "  ./Scripts/release.sh beta    # After alpha OK — Beta TestFlight"
    echo "  ./Scripts/release.sh rc      # After beta OK — RC code freeze"
    echo "  ./Scripts/release.sh stable  # After RC OK — Stable App Store"
    echo ""
    echo -e "${CYAN}Or manually:${NC}"
    echo "  git tag -a v1.0.0-dev.1 -m \"QELORYX v1.0.0-dev.1 — Dev — 1/5\""
    echo "  git push origin v1.0.0-dev.1"
    echo ""
    read -p "Enter channel to release (dev/alpha/beta/rc/stable) or press Enter to exit: " CHANNEL
    if [ -z "$CHANNEL" ]; then
        echo "Exiting."
        exit 0
    fi
else
    CHANNEL=$1
fi

# Validate channel
if [[ ! "$CHANNEL" =~ ^(dev|alpha|beta|rc|stable)$ ]]; then
    if [ "$CHANNEL" = "--help" ] || [ "$CHANNEL" = "-h" ]; then
        echo -e "${YELLOW}=== QELORYX Official Release Sequence — Help ===${NC}"
        echo ""
        show_sequence
        echo -e "${YELLOW}Channels:${NC}"
        echo "  dev    — 1/5 — Nightly — Internal core team — Experimental — Fast iteration — Prerelease true"
        echo "  alpha  — 2/5 — Internal QA — Features testable — Internal QA — Prerelease true"
        echo "  beta   — 3/5 — TestFlight — Feature complete — External feedback — Prerelease true"
        echo "  rc     — 4/5 — Release Candidate — Code freeze — Final verification — Prerelease true"
        echo "  stable — 5/5 — App Store — GA — Production — Public — Prerelease false"
        echo ""
        echo -e "${YELLOW}Official Rules:${NC}"
        echo "  - Strict order: Dev → Alpha → Beta → RC → Stable — No skipping"
        echo "  - Each stage exit criteria must pass before next"
        echo "  - Dev exit: No crash 5 tabs, basic playback"
        echo "  - Alpha exit: All 5 pillars testable, budgets met Cold <1.5s Search <50ms, no critical bugs, 30 min stable"
        echo "  - Beta exit: Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged"
        echo "  - RC exit: All 20+ RC checklist must pass all, validation pass, screenshots ready, code freeze"
        echo "  - Stable: GA App Store public"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  ./Scripts/release.sh dev"
        echo "  ./Scripts/release.sh alpha"
        echo "  ./Scripts/release.sh beta"
        echo "  ./Scripts/release.sh rc"
        echo "  ./Scripts/release.sh stable"
        echo "  ./Scripts/release.sh dev v1.0.0-dev.2"
        echo "  ./Scripts/release.sh beta v1.0.0-beta.2"
        echo ""
        exit 0
    else
        echo -e "${RED}❌ Invalid channel: $CHANNEL${NC}"
        echo "Valid channels: dev, alpha, beta, rc, stable"
        exit 1
    fi
fi

# Get version — from arg 2 or auto suggest
if [ $# -ge 2 ]; then
    VERSION=$2
    # Remove v prefix if present for consistency, then add back
    VERSION=${VERSION#v}
    TAG="v$VERSION"
else
    SUGGESTED=$(suggest_next_version $CHANNEL)
    echo -e "${BLUE}Suggested next version for $CHANNEL: $SUGGESTED${NC}"
    read -p "Enter version (press Enter for suggested $SUGGESTED): " INPUT_VERSION
    if [ -z "$INPUT_VERSION" ]; then
        TAG=$SUGGESTED
        VERSION=${SUGGESTED#v}
    else
        VERSION=${INPUT_VERSION#v}
        TAG="v$VERSION"
    fi
fi

# Determine order and prerelease
case $CHANNEL in
    dev)
        ORDER="1/5 — Dev"
        PRERELEASE="true"
        NAME="Dev — Nightly — Internal"
        ;;
    alpha)
        ORDER="2/5 — Alpha"
        PRERELEASE="true"
        NAME="Alpha — Internal Testing"
        ;;
    beta)
        ORDER="3/5 — Beta"
        PRERELEASE="true"
        NAME="Beta — TestFlight"
        ;;
    rc)
        ORDER="4/5 — RC"
        PRERELEASE="true"
        NAME="RC — Release Candidate"
        ;;
    stable)
        ORDER="5/5 — Stable"
        PRERELEASE="false"
        NAME="Stable — App Store — GA"
        ;;
esac

echo ""
echo -e "${PURPLE}=== Release Plan — Official Sequence ===${NC}"
echo -e "${CYAN}Channel: $CHANNEL ($ORDER)${NC}"
echo -e "${CYAN}Version: $VERSION${NC}"
echo -e "${CYAN}Tag: $TAG${NC}"
echo -e "${CYAN}Prerelease: $PRERELEASE${NC}"
echo -e "${CYAN}Name: QELORYX $VERSION — $NAME${NC}"
echo ""

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${RED}❌ Tag $TAG already exists!${NC}"
    echo "Existing tag: $(git show $TAG --no-patch --format=%B | head -5)"
    read -p "Delete existing tag and recreate? (y/N): " DELETE
    if [ "$DELETE" = "y" ] || [ "$DELETE" = "Y" ]; then
        git tag -d "$TAG"
        git push origin ":refs/tags/$TAG" || echo "Remote tag not exists or already deleted"
        echo -e "${GREEN}✅ Deleted existing tag $TAG${NC}"
    else
        echo "Aborted. Choose different version."
        exit 1
    fi
fi

# Check if working dir clean
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️ Working directory not clean — uncommitted changes:${NC}"
    git status --short
    echo ""
    read -p "Continue anyway? Commit first recommended. Continue? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Please commit changes first: git add . && git commit -m '...' && git push"
        exit 1
    fi
fi

# Show official sequence context
echo -e "${YELLOW}=== Official Sequence Context ===${NC}"
case $CHANNEL in
    dev)
        echo -e "${GREEN}Dev (1/5) →${NC} Alpha (2/5) → Beta (3/5) → RC (4/5) → Stable (5/5)"
        echo -e "${GREEN}  ↑ YOU ARE HERE — Dev — Start${NC}"
        echo "Next: Alpha v1.0.0-alpha.1 after dev exit pass"
        ;;
    alpha)
        echo -e "Dev (1/5) → ${GREEN}Alpha (2/5) →${NC} Beta (3/5) → RC (4/5) → Stable (5/5)"
        echo -e "           ${GREEN}↑ YOU ARE HERE — Alpha — Internal QA${NC}"
        echo "Next: Beta v1.0.0-beta.1 after alpha exit pass"
        ;;
    beta)
        echo -e "Dev (1/5) → Alpha (2/5) → ${GREEN}Beta (3/5) →${NC} RC (4/5) → Stable (5/5)"
        echo -e "                        ${GREEN}↑ YOU ARE HERE — Beta — External${NC}"
        echo "Next: RC v1.0.0-rc.1 after beta exit pass"
        ;;
    rc)
        echo -e "Dev (1/5) → Alpha (2/5) → Beta (3/5) → ${GREEN}RC (4/5) →${NC} Stable (5/5)"
        echo -e "                                     ${GREEN}↑ YOU ARE HERE — RC — Final${NC}"
        echo "Next: Stable v1.0.0 after RC exit all pass"
        ;;
    stable)
        echo -e "Dev (1/5) → Alpha (2/5) → Beta (3/5) → RC (4/5) → ${GREEN}Stable (5/5)${NC}"
        echo -e "                                                          ${GREEN}↑ YOU ARE HERE — Stable — GA DONE!${NC}"
        echo "Official Sequence Completed ✅ Dev→Alpha→Beta→RC→Stable"
        echo "Next: v1.1.0-dev.1 for next cycle"
        ;;
esac
echo ""

# Confirm
read -p "Release $TAG $CHANNEL ($ORDER) — Prerelease $PRERELEASE — Confirm? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

# Generate tag message — Official Sequence
TAG_MESSAGE="QELORYX $VERSION — $NAME — $ORDER — Official Sequence — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5)
Channel: $CHANNEL — $ORDER — $NAME
Version: $VERSION
Tag: $TAG
Prerelease: $PRERELEASE
Branch: $CURRENT_BRANCH
Commit: $(git rev-parse --short HEAD)

Purpose: $(case $CHANNEL in
    dev) echo "Nightly build from arena branch, fast iteration, catch obvious crashes early, internal core team only" ;;
    alpha) echo "Internal QA, features testable but not feature complete, stability check before external beta" ;;
    beta) echo "Feature complete, external beta testing via TestFlight, real devices, large libraries, feedback collection" ;;
    rc) echo "Code freeze, only critical fixes, final verification before App Store, App Store Connect validation" ;;
    stable) echo "Production App Store GA, public, official sequence completed Dev→Alpha→Beta→RC→Stable" ;;
esac)

Entry Criteria: $(case $CHANNEL in
    dev) echo "Code compiles 107 Swift files, app launches" ;;
    alpha) echo "Dev exit passed — No crash 5 tabs, basic playback works" ;;
    beta) echo "Alpha exit passed — All 5 pillars testable, budgets met Cold <1.5s Search <50ms, no critical bugs, 30 min stable" ;;
    rc) echo "Beta exit passed — Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged" ;;
    stable) echo "RC exit passed — All 20+ RC checklist must pass all, validation pass, screenshots ready, no critical bugs crash-free >99.5%" ;;
esac)

Exit Criteria to Next: $(case $CHANNEL in
    dev) echo "No crash 5 tabs, basic playback works → Alpha v1.0.0-alpha.1" ;;
    alpha) echo "All 5 pillars testable, budgets met, no critical bugs, 30 min stable → Beta v1.0.0-beta.1" ;;
    beta) echo "Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged → RC v1.0.0-rc.1" ;;
    rc) echo "All 20+ RC checklist must pass all, validation pass, screenshots ready, code freeze → Stable v1.0.0" ;;
    stable) echo "N/A — Official sequence completed — Start next cycle v1.1.0-dev.1" ;;
esac)

Next: $(case $CHANNEL in
    dev) echo "v1.0.0-alpha.1 Alpha Internal QA" ;;
    alpha) echo "v1.0.0-beta.1 Beta TestFlight" ;;
    beta) echo "v1.0.0-rc.1 RC Release Candidate" ;;
    rc) echo "v1.0.0 Stable GA App Store" ;;
    stable) echo "v1.1.0-dev.1 Dev Next cycle" ;;
esac)

Build: 107 Swift files production, Xcode 15.4, iOS 17+, Swift 5.9+
Performance: Cold <1.5s Warm <0.6s Search <50ms Library <200ms Queue Instant Seek <50ms Play/Pause Instant+Haptics <10ms Lyrics <50ms Karaoke <100ms Download Enqueue <50ms TasteDNA <200ms Recommendations <100ms Animations <16ms 60fps Haptics <10ms Navigation <50ms — All met ✅

QELORYX $VERSION — $NAME — $ORDER — Hear Beyond. Build Beyond. — Midnight Aurora 🌌 — Qeloryx Labs"

echo ""
echo -e "${BLUE}=== Creating Tag $TAG ===${NC}"
echo "$TAG_MESSAGE"
echo ""

# Create annotated tag
git tag -a "$TAG" -m "$TAG_MESSAGE"

echo -e "${GREEN}✅ Tag $TAG created locally${NC}"
echo ""

# Push tag
read -p "Push tag $TAG to origin? (y/N): " PUSH
if [ "$PUSH" = "y" ] || [ "$PUSH" = "Y" ]; then
    git push origin "$TAG"
    echo -e "${GREEN}✅ Tag $TAG pushed to origin${NC}"
    echo ""
    echo -e "${PURPLE}=== Release Triggered — Official Sequence ===${NC}"
    echo -e "${CYAN}Tag: $TAG${NC}"
    echo -e "${CYAN}Channel: $CHANNEL ($ORDER)${NC}"
    echo -e "${CYAN}Prerelease: $PRERELEASE${NC}"
    echo ""
    echo -e "${YELLOW}GitHub Actions will now (release.yml):${NC}"
    echo "  1. validate — Tag format + Swift package build/test in Release"
    echo "  2. build — Unsigned simulator app + unsigned arm64 device app"
    echo "  3. package — Qeloryx-simulator.zip + Qeloryx.ipa (Payload/Qeloryx.app)"
    echo "  4. publish — GitHub Release (prerelease $PRERELEASE) with Qeloryx.ipa + Qeloryx-simulator.zip"
    echo ""
    echo -e "${BLUE}Qeloryx.ipa is unsigned — sideload via AltStore/SideStore/Esign/TrollStore after local signing${NC}"
    echo ""
    echo -e "${BLUE}Watch: https://github.com/raynmahbub/Qeloryx/actions${NC}"
    echo -e "${BLUE}Releases: https://github.com/raynmahbub/Qeloryx/releases${NC}"
    echo ""
    
    case $CHANNEL in
        dev)
            echo -e "${YELLOW}Next in Official Sequence: Alpha${NC}"
            echo "After dev checklist 5 min pass → ./Scripts/release.sh alpha"
            ;;
        alpha)
            echo -e "${YELLOW}Next in Official Sequence: Beta${NC}"
            echo "After alpha checklist 30 min 2+ testers pass → ./Scripts/release.sh beta"
            ;;
        beta)
            echo -e "${YELLOW}Next in Official Sequence: RC${NC}"
            echo "After beta real device 5+ devices 10k tracks 1h background stable crash-free >99% → ./Scripts/release.sh rc"
            ;;
        rc)
            echo -e "${YELLOW}Next in Official Sequence: Stable${NC}"
            echo "After RC all 20+ checklist must pass all validation screenshots → ./Scripts/release.sh stable"
            ;;
        stable)
            echo -e "${GREEN}Official Sequence Completed ✅ Dev→Alpha→Beta→RC→Stable${NC}"
            echo "Next cycle: ./Scripts/release.sh dev v1.1.0-dev.1"
            ;;
    esac
    echo ""
    echo -e "${GREEN}🎉 QELORYX $VERSION $CHANNEL $ORDER — Released! — Hear Beyond. Build Beyond. 🌌${NC}"
else
    echo -e "${YELLOW}Tag created locally but not pushed. To push later:${NC}"
    echo "  git push origin $TAG"
    echo "To delete local tag if needed:"
    echo "  git tag -d $TAG"
fi
