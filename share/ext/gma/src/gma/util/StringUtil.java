package gma.util;

/**
 * <p>Title: </p>
 * <p>Description: StringUtil is a utility class for string manipulation.</p>
 * <p>Copyright: Copyright (c) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

public class StringUtil {

  /**
   * Normalizes string.
   * @param source                    source string for normalization
   * @return                          normalized string
   */
  public static String norm(String source) {
    String destination = "";
    for (int index = 0; index < source.length(); index++) {
      char c = source.charAt(index);
      switch (c) {
        case '�': destination += 'A'; break;
        case '�': destination += 'A'; break;
        case '�': destination += 'A'; break;
        case '�': destination += 'A'; break;
        case '�': destination += 'A'; break;
        case '�': destination += 'A'; break;
        case '�': destination += 'C'; break;
        case '�': destination += 'E'; break;
        case '�': destination += 'E'; break;
        case '�': destination += 'E'; break;
        case '�': destination += 'E'; break;
        case '�': destination += 'I'; break;
        case '�': destination += 'I'; break;
        case '�': destination += 'I'; break;
        case '�': destination += 'I'; break;
        case '�': destination += 'N'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'O'; break;
        case '�': destination += 'U'; break;
        case '�': destination += 'U'; break;
        case '�': destination += 'U'; break;
        case '�': destination += 'U'; break;
        case '�': destination += 'a'; break;
        case '�': destination += 'a'; break;
        case '�': destination += 'a'; break;
        case '�': destination += 'a'; break;
        case '�': destination += 'a'; break;
        case '�': destination += "ae"; break;
        case '�': destination += 'c'; break;
        case '�': destination += 'e'; break;
        case '�': destination += 'e'; break;
        case '�': destination += 'e'; break;
        case '�': destination += 'e'; break;
        case '�': destination += 'i'; break;
        case '�': destination += 'i'; break;
        case '�': destination += 'i'; break;
        case '�': destination += 'i'; break;
        case '�': destination += 'n'; break;
        case '�': destination += 'o'; break;
        case '�': destination += 'o'; break;
        case '�': destination += 'o'; break;
        case '�': destination += 'o'; break;
        case '�': destination += 'o'; break;
        case '�': destination += "ss"; break;
        case '�': destination += 'u'; break;
        case '�': destination += 'u'; break;
        case '�': destination += 'u'; break;
        case '�': destination += 'u'; break;
        case '�': destination += 'y'; break;
        default: destination += c; break;
      }
    }
    return destination;
  }
}
