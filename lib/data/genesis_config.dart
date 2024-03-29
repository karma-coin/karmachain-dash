import 'package:fixnum/fixnum.dart';
import 'package:karmachain_dash/data/personality_traits.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/common_libs.dart';

class CommunityDesignTheme {
  Color backgroundColor;
  Color textColor;
  CommunityDesignTheme(this.backgroundColor, this.textColor);
}

class GenesisConfig {
  static const kCentsPerCoin = 1000000;

  /// Karmachain netId. 1 is testnet 1
  static const netId = 1;

  static const netName = "Karmachain Testnet 1";

  /// Signup reward in kCents (phase I reward)
  static final kCentsSignupReward = Int64(10 * kCentsPerCoin);

  /// Default user tx fee
  static const kCentsDefaultFee = Int64.ONE;

  /// Default personality trait index for trait picket
  static const defaultAppreciationTraitIndex = 27;

  /// Trait index for sign up. e.g. a Karma Grower
  static const signUpCharTraitIndex = 2;

  /// Trait index for no appreciation - used in payemnt transactions
  static const noAppreciationTraitIndex = 0;

  // todo: unify all of these props into community ClientData object and store
  // in map by community id

  /// todo: move to community manager - not part og genesis config
  static final Map<int, CommunityDesignTheme> communityColors = {
    1: CommunityDesignTheme(const Color.fromARGB(255, 183, 66, 179),
        const Color.fromARGB(255, 255, 255, 255)),
  };

  static final Map<int, String> communityTileAssets = {
    1: 'assets/images/giraffes_tile.png',
  };

  static final Map<int, String> communityBannerAssets = {
    1: 'assets/images/giraffes_banner.png',
  };

  static final Map<int, String> communityAppreciateLabels = {
    1: '🦒 Appreciate a Giraffe',
  };

  static final Map<int, String> communityHomeScreenPaths = {
    1: '/community/giraffes',
  };

  // todo: add asset for banner

  /// Meta-data for partner communitites supported by the app index by id
  static final Map<int, Community> communities = {
    1: Community(
        id: 1,
        name: 'Grateful Giraffes',
        desc:
            'A global community of leaders that come together for powerful wellness experiences',
        emoji: '🦒',
        websiteUrl: 'https://www.gratefulgiraffes.com',
        twitterUrl: 'https://twitter.com/TheGratefulDAO',
        instaUrl: 'https://www.instagram.com/gratefulgiraffes',
        discordUrl: 'https://discord.gg/7FMTXavy8N',
        charTraitIds: [10, 4, 3, 11, 15, 18, 39, 42, 60])
  };

  static final Map<int, List<PersonalityTrait>> communityPersonalityTraits = {
    1: [
      PersonalityTrait(10, 'Grateful', '🦒'),
      PersonalityTrait(4, 'Helpful', '🤗'),
      PersonalityTrait(3, 'Kind', '🤗'),
      PersonalityTrait(11, 'Spiritual', '🕊️'),
      PersonalityTrait(15, 'Generous', '🎁'),
      PersonalityTrait(18, 'Creative', '🎨'),
      PersonalityTrait(39, 'a Healer', '🌿'),
      PersonalityTrait(42, 'an Inspiration', '🌟'),
      PersonalityTrait(60, 'an Imaginative Motivator', '🌻'),
    ]
  };

  static final List<PersonalityTrait> personalityTraits = [
    PersonalityTrait(0, '', ''),
    // user gets it for on signup
    PersonalityTrait(1, 'a Karma Grower', '💚'),
    // user gets one point in this for every payment tx (w/o appreciation) sent by a user and executed
    PersonalityTrait(2, 'a Karma Spender', '🙏'),
    PersonalityTrait(3, 'Kind', '🤗'),
    PersonalityTrait(4, 'Helpful', '🤗'),
    PersonalityTrait(5, 'an Uber Geek', '🤓'),
    PersonalityTrait(6, 'Awesome', '🤩'),
    PersonalityTrait(7, 'Smart', '🧠'),
    PersonalityTrait(8, 'Sexy', '🔥'),
    PersonalityTrait(9, 'Patient', '🐛'),
    PersonalityTrait(10, 'Grateful', '🦒'),
    PersonalityTrait(11, 'Spiritual', '🕊️'),
    PersonalityTrait(12, 'Funny', '🤣'),
    PersonalityTrait(13, 'Caring', '🤲'),
    PersonalityTrait(14, 'Loving', '💕'),
    PersonalityTrait(15, 'Generous', '🎁'),
    PersonalityTrait(16, 'Honest', '🤝'),
    PersonalityTrait(17, 'Respectful', '🎩'),
    PersonalityTrait(18, 'Creative', '🎨'),
    PersonalityTrait(19, 'Intelligent', '📚'),
    PersonalityTrait(20, 'Loyal', '🦒'),
    PersonalityTrait(21, 'Trustworthy', '👌'),
    PersonalityTrait(22, 'Humble', '🌱'),
    PersonalityTrait(23, 'Courageous', '🦁'),
    PersonalityTrait(24, 'Confident', '🌞'),
    PersonalityTrait(25, 'Passionate', '🌹'),
    PersonalityTrait(26, 'Optimistic', '😃'),
    PersonalityTrait(27, 'Adventurous', '🧗‍♂️'),
    PersonalityTrait(28, 'Determined', '🏹'),
    PersonalityTrait(29, 'Selfless', '😇'),
    PersonalityTrait(30, 'Self-aware', '🤔'),
    PersonalityTrait(31, 'Present', '🦢'),
    PersonalityTrait(32, 'Self-disciplined', '💪'),
    PersonalityTrait(33, 'Mindful', '🧘'),
    PersonalityTrait(34, 'My Guardian Angel', '👼'),
    PersonalityTrait(35, 'a Fairy', '🧚'),
    PersonalityTrait(36, 'a Wizard', '🧙‍♂️'),
    PersonalityTrait(37, 'a Witch', '🔮'),
    PersonalityTrait(38, 'a Warrior', '🥷'),
    PersonalityTrait(39, 'a Healer', '🌿'),
    PersonalityTrait(40, 'a Guardian', '🛡️'),

    // User gets this for every referal tx that converted to a new user
    PersonalityTrait(41, 'a Karma Ambassador', '💌'),

    PersonalityTrait(42, 'an Inspiration', '🌟'),
    PersonalityTrait(43, 'a Sleeping Beauty', '👸'),
    PersonalityTrait(44, 'a Healer', '❤️‍🩹'),
    PersonalityTrait(45, 'a Master Mind', '💡'),
    PersonalityTrait(46, 'a Counselor', '🫶'),
    PersonalityTrait(47, 'an Architect', '🏛️'),
    PersonalityTrait(48, 'a Champion', '🏆'),
    PersonalityTrait(49, 'a Commander', '👨‍✈️'),
    PersonalityTrait(50, 'a Visionary', '👁️'),
    PersonalityTrait(51, 'a Teacher', '👩‍🏫'),
    PersonalityTrait(52, 'an Craftsperson', '🛠️'),
    PersonalityTrait(53, 'an Inspector', '🔍'),
    PersonalityTrait(54, 'a Composer', '📝'),
    PersonalityTrait(55, 'a Protector', '⚔️'),
    PersonalityTrait(56, 'a Provider', '🤰'),
    PersonalityTrait(57, 'a Performer', '🎭'),
    PersonalityTrait(58, 'a Supervisor', '🕵️‍♀️'),
    PersonalityTrait(59, 'a Dynamo', '🚀'),
    PersonalityTrait(60, 'an Imaginative Motivator', '🌻'),
    PersonalityTrait(61, 'a Campaigner', '📣'),
    PersonalityTrait(62, 'A Karma Rewards Winner', '🏆'),
  ];
}
